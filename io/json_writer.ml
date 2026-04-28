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

let cell_to_json = function
  | VInt i -> string_of_int i
  | VFloat f -> string_of_float f
  | VString s -> "\"" ^ escape_json_string s ^ "\""
  | VNull -> "null"

let write_json filename schema seq =
  let oc = open_out filename in
  let headers = List.map fst schema in
  let types =
    List.map
      (fun (_, t) ->
        match t with TInt -> "\"Int\"" | TFloat -> "\"Float\"" | TString -> "\"String\"")
      schema
  in

  output_string oc "{\n";
  output_string oc ("  \"columns\": [" ^ String.concat ", " (List.map (fun h -> "\"" ^ escape_json_string h ^ "\"") headers) ^ "],\n");
  output_string oc ("  \"datatypes\": [" ^ String.concat ", " types ^ "],\n");
  output_string oc "  \"data\": [\n";
  
  let first = ref true in
  Seq.iter
    (fun row ->
      let row_values = List.map (fun h -> match List.assoc_opt h row with Some c -> cell_to_json c | None -> "null") headers in
      if !first then first := false else output_string oc ",\n";
      output_string oc ("    [" ^ String.concat ", " row_values ^ "]")
    ) seq;
    
  output_string oc "\n  ]\n}\n";
  close_out oc