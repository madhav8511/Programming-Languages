(* io/json_writer.ml *)
open Data_type

let escape_json_string s =
  let buf = Buffer.create (String.length s) in
  String.iter
    (function
      | '"' -> Buffer.add_string buf "\\\""
      | '\\' -> Buffer.add_string buf "\\\\"
      | '\n' -> Buffer.add_string buf "\\n"
      | '\r' -> Buffer.add_string buf "\\r"
      | '\t' -> Buffer.add_string buf "\\t"
      | c -> Buffer.add_char buf c)
    s;
  Buffer.contents buf

let quote s = "\"" ^ escape_json_string s ^ "\""

let type_to_json = function
  | TInt -> quote "Int"
  | TFloat -> quote "Float"
  | TString -> quote "String"

let float_to_json f =
  match classify_float f with
  | FP_normal | FP_subnormal | FP_zero -> Printf.sprintf "%.15g" f
  | FP_infinite | FP_nan -> "null"

let cell_to_json = function
  | VInt i -> string_of_int i
  | VFloat f -> float_to_json f
  | VString s -> quote s
  | VNull -> "null"

let write_json filename schema seq =
  let oc = open_out filename in
  let headers = List.map fst schema in
  let schema_fields =
    List.map (fun (name, dtype) -> quote name ^ ":" ^ type_to_json dtype) schema
  in
  output_string oc ("{\"__schema__\":{" ^ String.concat "," schema_fields ^ "}}\n");

  Seq.iter
    (fun row ->
      let fields =
        List.map
          (fun h ->
            let value =
              match List.assoc_opt h row with
              | Some c -> cell_to_json c
              | None -> "null"
            in
            quote h ^ ":" ^ value)
          headers
      in
      output_string oc ("{" ^ String.concat "," fields ^ "}\n"))
    seq;
  close_out oc
