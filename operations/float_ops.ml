(* src/operations/float_ops.ml *)
open Data_type

let add_bonus col_name bonus seq =
  Seq.map (fun row ->
    List.map (fun (k, v) ->
      if k = col_name then
        match v with
        | VFloat f -> (k, VFloat (f +. bonus))
        | _ -> (k, v)
      else (k, v)
    ) row
  ) seq

let total col_name seq =
  Seq.fold_left (fun acc row ->
    match List.assoc_opt col_name row with
    | Some (VFloat f) -> acc +. f
    | _ -> acc
  ) 0.0 seq