(* operations/aggregate_ops.ml *)
open Data_type

type agg_fn = Sum | Count | Mean | Min | Max

(* 1. Immutable Accumulator *)
type acc = {
  sum   : float;
  count : int;
  min_v : float;
  max_v : float;
}

let init_acc =
  { sum = 0.0; count = 0;
    min_v = Float.infinity;
    max_v = Float.neg_infinity }

let update_acc a v =
  { sum = a.sum +. v;
    count = a.count + 1;
    min_v = min a.min_v v;
    max_v = max a.max_v v }

let finalise fn a =
  match fn with
  | Sum   -> VFloat a.sum
  | Count -> VInt   a.count
  | Mean  -> if a.count = 0 then VNull
             else VFloat (a.sum /. float_of_int a.count)
  | Min   -> if a.count = 0 then VNull else VFloat a.min_v
  | Max   -> if a.count = 0 then VNull else VFloat a.max_v

let cell_to_float = function
  | VInt   i -> Some (float_of_int i)
  | VFloat f -> Some f
  | _        -> None

(* 2. Global Aggregate (Pure Fold) *)
let global_agg col fn seq =
  let final_acc = Seq.fold_left (fun a row ->
    match List.assoc_opt col row with
    | Some c -> 
        (match cell_to_float c with 
         | Some v -> update_acc a v 
         | None -> a)
    | None -> a
  ) init_acc seq in
  finalise fn final_acc

(* 3. Group-By Aggregate (Immutable Map + Fold) *)
module StringMap = Map.Make(String)

let group_by key_col agg_col fn seq =
  (* Single streaming pass using purely functional folding *)
  let folded_map = Seq.fold_left (fun map row ->
    let key =
      match List.assoc_opt key_col row with
      | Some (VString s) -> s
      | Some (VInt    i) -> string_of_int i
      | Some (VFloat  f) -> string_of_float f
      | _                -> "__null__"
    in
    
    (* Get current state or initialize a new one *)
    let current_acc = 
      match StringMap.find_opt key map with
      | Some a -> a
      | None   -> init_acc
    in
    
    (* Calculate new state *)
    let new_acc = 
      match List.assoc_opt agg_col row with
      | Some c -> 
          (match cell_to_float c with 
           | Some v -> update_acc current_acc v 
           | None -> current_acc)
      | None -> current_acc
    in
    
    (* Return updated map to the next step of the fold *)
    StringMap.add key new_acc map
  ) StringMap.empty seq in

  (* Return results as a lazy Seq of (key_col, agg_col) rows *)
  StringMap.bindings folded_map
  |> List.map (fun (key, acc) ->
       [(key_col, VString key); (agg_col, finalise fn acc)]
     )
  |> List.to_seq

(* --- Printers --- *)
let print_agg_results label col result =
  Printf.printf "\n--- %s ---\n" label;
  match result with
  | VInt   i -> Printf.printf "%s = %d\n" col i
  | VFloat f -> Printf.printf "%s = %.2f\n" col f
  | VNull    -> Printf.printf "%s = NULL\n" col
  | VString s -> Printf.printf "%s = %s\n" col s

let print_group_results label seq =
  Printf.printf "\n--- %s ---\n" label;
  Seq.iter (fun row ->
    let pairs = List.map (fun (k, v) ->
      let vs = match v with
        | VInt i -> string_of_int i
        | VFloat f -> Printf.sprintf "%.2f" f
        | VString s -> s
        | VNull -> "NULL"
      in
      k ^ "=" ^ vs
    ) row in
    Printf.printf "  %s\n" (String.concat " | " pairs)
  ) seq