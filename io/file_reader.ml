(* io/file_reader.ml *)
open Data_type

(* Safely strip quotes and determine type *)
let parse_type s =
  let s_clean = String.lowercase_ascii (String.trim s) in
  let s_clean = 
    if String.length s_clean >= 2 && s_clean.[0] = '"' then
      String.sub s_clean 1 (String.length s_clean - 2)
    else s_clean 
  in
  match s_clean with
  | "int" -> TInt
  | "float" -> TFloat
  | _ -> TString

let parse_cell expected_type str_val =
  let s = String.trim str_val in
  if s = "" then VNull
  else try
    match expected_type with
    | TInt -> VInt (int_of_string s)
    | TFloat -> VFloat (float_of_string s)
    | TString -> VString s
  with Failure _ -> VNull

let read_csv_with_schema filename =
  let ic = open_in filename in
  
  (* 1. Read Headers and Types *)
  let header_line = try input_line ic with End_of_file -> "" in
  let type_line = try input_line ic with End_of_file -> "" in

  let headers = List.map String.trim (String.split_on_char ',' header_line) in
  let type_strings = List.map String.trim (String.split_on_char ',' type_line) in

  (* 2. Build Schema *)
  let rec zip_schema hs ts acc =
    match hs, ts with
    | [], _ | _, [] -> List.rev acc
    | h::ht, t::tt -> zip_schema ht tt ((h, parse_type t) :: acc)
  in
  let schema = zip_schema headers type_strings [] in

  (* 3. Parse Data Lazily using Seq.of_dispenser *)
  let parse_row line =
    let values = String.split_on_char ',' line in
    let rec zip_row sch vals acc =
      match sch, vals with
      | [], _ | _, [] -> List.rev acc
      | (col_name, col_type)::st, v::vt ->
          zip_row st vt ((col_name, parse_cell col_type v) :: acc)
    in
    zip_row schema values []
  in

  let lazy_stream = Seq.of_dispenser (fun () ->
    try
      let line = input_line ic in
      Some (parse_row line)
    with End_of_file ->
      close_in ic;
      None
  ) in
  
  (schema, lazy_stream)