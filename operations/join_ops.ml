(* operations/join_ops.ml *)
open Data_type

module StringMap = Map.Make(String)

let cell_to_key = function
  | VString s -> s
  | VInt    i -> string_of_int i
  | VFloat  f -> string_of_float f
  | VNull     -> "__null__"

let merge_rows left_row right_row left_cols =
  let right_new =
    List.filter (fun (col, _) -> not (List.mem col left_cols)) right_row
  in
  left_row @ right_new

let null_right_row right_schema left_cols =
  List.filter_map (fun (col, _) ->
    if List.mem col left_cols then None else Some (col, VNull)
  ) right_schema

(* ================================================================== *)
(* HASH JOINS (Use when the RIGHT table is small enough to fit in RAM)*)
(* ================================================================== *)

let inner_join key_col left_schema left_stream right_schema right_stream =
  
  (* 1. Load right table into immutable Map via fold *)
  let right_map = Seq.fold_left (fun map row ->
    match List.assoc_opt key_col row with
    | Some k -> StringMap.add (cell_to_key k) row map
    | None   -> map
  ) StringMap.empty right_stream in

  (* 2. Merged schema logic *)
  let left_cols = List.map fst left_schema in
  let right_schema_new =
    List.filter (fun (col, _) -> not (List.mem col left_cols)) right_schema
  in
  let merged_schema = left_schema @ right_schema_new in

  (* 3. Lazy stream processing *)
  let merged_stream =
    Seq.filter_map (fun left_row ->
      match List.assoc_opt key_col left_row with
      | None   -> None
      | Some k ->
          let key = cell_to_key k in
          match StringMap.find_opt key right_map with
          | None           -> None
          | Some right_row -> Some (merge_rows left_row right_row left_cols)
    ) left_stream
  in
  (merged_schema, merged_stream)


let left_join key_col left_schema left_stream right_schema right_stream =
  
  let right_map = Seq.fold_left (fun map row ->
    match List.assoc_opt key_col row with
    | Some k -> StringMap.add (cell_to_key k) row map
    | None   -> map
  ) StringMap.empty right_stream in

  let left_cols = List.map fst left_schema in
  let right_schema_new =
    List.filter (fun (col, _) -> not (List.mem col left_cols)) right_schema
  in
  let merged_schema = left_schema @ right_schema_new in
  let null_right = null_right_row right_schema left_cols in

  let merged_stream =
    Seq.map (fun left_row ->
      match List.assoc_opt key_col left_row with
      | None   -> left_row @ null_right
      | Some k ->
          let key = cell_to_key k in
          let right_row =
            match StringMap.find_opt key right_map with
            | Some r -> r
            | None   -> null_right
          in
          merge_rows left_row right_row left_cols
    ) left_stream
  in
  (merged_schema, merged_stream)

  
(* SORT-MERGE JOIN (Fully Lazy, 0MB Memory)                           *)
(* REQUIRES: Both input streams MUST be pre-sorted by the key_col     *)
(* Helper to safely extract a string key for comparison *)

let get_key key_col row =
  match List.assoc_opt key_col row with
  | Some k -> cell_to_key k
  | None -> "__null__"

let fully_lazy_join key_col left_schema left_stream right_schema right_stream =
  
  let left_cols = List.map fst left_schema in
  let right_schema_new =
    List.filter (fun (col, _) -> not (List.mem col left_cols)) right_schema
  in
  let merged_schema = left_schema @ right_schema_new in

  (* The recursive sequence generator *)
  let rec merge_step l_seq r_seq () =
    match l_seq (), r_seq () with
    | Seq.Nil, _ | _, Seq.Nil -> 
        (* If either file hits the end, the inner join is finished *)
        Seq.Nil 
    | Seq.Cons (l_row, l_next), Seq.Cons (r_row, r_next) ->
        let l_key = get_key key_col l_row in
        let r_key = get_key key_col r_row in
        
        let cmp = String.compare l_key r_key in
        
        if cmp = 0 then
          (* Keys match! Merge the rows and advance BOTH streams *)
          let merged = merge_rows l_row r_row left_cols in
          Seq.Cons (merged, merge_step l_next r_next)
          
        else if cmp < 0 then
          (* Left key is alphabetically behind Right key. Advance LEFT. *)
          (* We pass the current r_seq (fun () -> Seq.Cons(...)) back in *)
          merge_step l_next (fun () -> Seq.Cons (r_row, r_next)) ()
          
        else
          (* Right key is alphabetically behind Left key. Advance RIGHT. *)
          merge_step (fun () -> Seq.Cons (l_row, l_next)) r_next ()
  in

  let merged_stream = merge_step left_stream right_stream in
  (merged_schema, merged_stream)