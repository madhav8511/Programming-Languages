(* src/io/file_writer.ml *)
open Data_type

let cell_to_string = function
  | VInt i -> string_of_int i
  | VFloat f -> string_of_float f
  | VString s -> s
  | VNull -> ""

let type_to_string = function
  | TInt -> "\"Int\""
  | TFloat -> "\"Float\""
  | TString -> "\"String\""

let write_csv filename schema seq =
  let oc = open_out filename in
  let headers = List.map fst schema in
  let types = List.map (fun (_, t) -> type_to_string t) schema in
  
  (* Write Row 1 (Headers) and Row 2 (Types) *)
  output_string oc (String.concat "," headers ^ "\n");
  output_string oc (String.concat "," types ^ "\n");

  (* Write Data *)
  Seq.iter (fun row ->
    let row_strings = List.map (fun h ->
      match List.assoc_opt h row with
      | Some c -> cell_to_string c
      | None -> ""
    ) headers in
    output_string oc (String.concat "," row_strings ^ "\n")
  ) seq;
  close_out oc