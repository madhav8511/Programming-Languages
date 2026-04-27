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

let add_dept_bonus target_col dept_col dept_name bonus seq =
  Seq.map (fun row ->
    let qualifies = match List.assoc_opt dept_col row with
      | Some (VString d) when d = dept_name -> true
      | _ -> false
    in
    if qualifies then
      List.map (fun (k, v) ->
        if k = target_col then
          match v with
          | VFloat f -> (k, VFloat (f +. bonus))
          | VInt i -> (k, VFloat (float_of_int i +. bonus))
          | _ -> (k, v)
        else (k, v)
      ) row
    else
      row
  ) seq

let total col_name seq =
  Seq.fold_left (fun acc row ->
    match List.assoc_opt col_name row with
    | Some (VFloat f) -> acc +. f
    | _ -> acc
  ) 0.0 seq


let min_max_scale col_name min_val max_val seq =
  let range = max_val -. min_val in
  Seq.map (fun row ->
    List.map (fun (k, v) ->
      if k = col_name then
        match v with
        | VFloat f -> 
            let scaled_val = (f -. min_val) /. range in
            (k, VFloat scaled_val)
        | _ -> (k, v)
      else (k, v)
    ) row
  ) seq

let get_stats col_name seq =
  let sum, sum_sq, count = Seq.fold_left (fun (s, sq, c) row ->
    let val_opt = match List.assoc_opt col_name row with
      | Some (VFloat f) -> Some f
      | Some (VInt i) -> Some (float_of_int i)
      | _ -> None
    in
    match val_opt with
    | Some v -> (s +. v, sq +. (v *. v), c + 1)
    | None -> (s, sq, c)
  ) (0.0, 0.0, 0) seq in
  
  if count = 0 then (0.0, 1.0)
  else
    let n = float_of_int count in
    let mean = sum /. n in
    let variance = (sum_sq /. n) -. (mean *. mean) in
    let std_dev = if variance > 0.0 then sqrt variance else 1.0 in
    (mean, std_dev)


let standardize col_name mean_val std_dev_val seq =
  Seq.map (fun row ->
    List.map (fun (k, v) ->
      if k = col_name then
        match v with
        | VFloat f -> 
            let z_score = (f -. mean_val) /. std_dev_val in
            (k, VFloat z_score)
        | VInt i -> 
            let f = float_of_int i in
            let z_score = (f -. mean_val) /. std_dev_val in
            (k, VFloat z_score)
        | _ -> (k, v)
      else (k, v)
    ) row
  ) seq