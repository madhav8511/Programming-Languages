open Data_type

let filter_min col_name min_val seq =
  Seq.filter (fun row ->
    match List.assoc_opt col_name row with
    | Some (VInt i) -> i >= min_val
    | _ -> false
  ) seq

let mean col_name seq =
  let sum, count = Seq.fold_left (fun (s, c) row ->
    match List.assoc_opt col_name row with
    | Some (VInt i) -> (s + i, c + 1)
    | _ -> (s, c)
  ) (0, 0) seq in
  if count = 0 then 0.0 else float_of_int sum /. float_of_int count