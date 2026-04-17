(* operations.ml *)
open Types

(* --- 1 & 2: FILTERS --- *)

let filter_min_age (min_age : int) (seq : dataobject Seq.t) =
  Seq.filter (fun row ->
    match List.assoc_opt "Age" row with
    | Some (VInt a) -> a >= min_age
    | _ -> false
  ) seq

let filter_max_age (max_age : int) (seq : dataobject Seq.t) =
  Seq.filter (fun row ->
    match List.assoc_opt "Age" row with
    | Some (VInt a) -> a <= max_age
    | _ -> false
  ) seq

(* --- 3, 4 & 5: MAPS (Transformations) --- *)

let name_to_uppercase (seq : dataobject Seq.t) =
  Seq.map (fun row ->
    List.map (fun (k, v) ->
      if k = "Name" then
        match v with
        | VString s -> (k, VString (String.uppercase_ascii s))
        | _ -> (k, v)
      else (k, v)
    ) row
  ) seq

let name_to_lowercase (seq : dataobject Seq.t) =
  Seq.map (fun row ->
    List.map (fun (k, v) ->
      if k = "Name" then
        match v with
        | VString s -> (k, VString (String.lowercase_ascii s))
        | _ -> (k, v)
      else (k, v)
    ) row
  ) seq

let give_salary_bonus (bonus : float) (seq : dataobject Seq.t) =
  Seq.map (fun row ->
    List.map (fun (k, v) ->
      if k = "Salary" then
        match v with
        | VFloat f -> (k, VFloat (f +. bonus))
        | VInt i -> (k, VFloat (float_of_int i +. bonus))
        | _ -> (k, v)
      else (k, v)
    ) row
  ) seq

(* --- 6, 7 & 8: AGGREGATIONS --- *)
(* Aggregations consume the stream to return a single value *)

let total_salary (seq : dataobject Seq.t) : float =
  Seq.fold_left (fun acc row ->
    match List.assoc_opt "Salary" row with
    | Some (VFloat f) -> acc +. f
    | Some (VInt i) -> acc +. float_of_int i
    | _ -> acc
  ) 0.0 seq

let mean_salary (seq : dataobject Seq.t) : float =
  let total, count = Seq.fold_left (fun (sum, n) row ->
    match List.assoc_opt "Salary" row with
    | Some (VFloat f) -> (sum +. f, n + 1)
    | Some (VInt i) -> (sum +. float_of_int i, n + 1)
    | _ -> (sum, n)
  ) (0.0, 0) seq in
  if count = 0 then 0.0 else total /. float_of_int count

let mean_age (seq : dataobject Seq.t) : float =
  let total, count = Seq.fold_left (fun (sum, n) row ->
    match List.assoc_opt "Age" row with
    | Some (VInt a) -> (sum +. float_of_int a, n + 1)
    | _ -> (sum, n)
  ) (0.0, 0) seq in
  if count = 0 then 0.0 else total /. float_of_int count