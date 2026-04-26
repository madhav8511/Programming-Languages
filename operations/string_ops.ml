(* src/operations/string_ops.ml *)
open Data_type

let to_uppercase col_name seq =
  Seq.map (fun row ->
    List.map (fun (k, v) ->
      if k = col_name then
        match v with
        | VString s -> (k, VString (String.uppercase_ascii s))
        | _ -> (k, v)
      else (k, v)
    ) row
  ) seq

let to_lowercase col_name seq =
  Seq.map (fun row ->
    List.map (fun (k, v) ->
      if k = col_name then
        match v with
        | VString s -> (k, VString (String.lowercase_ascii s))
        | _ -> (k, v)
      else (k, v)
    ) row
  ) seq

let append_suffix col_name suffix seq =
  Seq.map (fun row ->
    List.map (fun (k, v) ->
      if k = col_name then
        match v with
        | VString s -> (k, VString (s ^ suffix))
        | _ -> (k, v)
      else (k, v)
    ) row
  ) seq