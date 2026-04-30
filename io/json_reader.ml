(* io/json_reader.ml *)
open Data_type

let parse_type s =
  match String.lowercase_ascii (String.trim s) with
  | "int" -> TInt
  | "float" -> TFloat
  | _ -> TString

let parse_cell expected_type str_val =
  let s = String.trim str_val in
  if s = "" then VNull
  else
    try
      match expected_type with
      | TInt -> VInt (int_of_string s)
      | TFloat -> VFloat (float_of_string s)
      | TString -> VString s
    with Failure _ -> VNull

type json_scalar =
  | JString of string
  | JNumber of string
  | JNull

let is_ws = function
  | ' ' | '\n' | '\r' | '\t' -> true
  | _ -> false

type ctx = { s : string; len : int; mutable pos : int }

let make_ctx s = { s; len = String.length s; pos = 0 }

let skip_ws ctx =
  while ctx.pos < ctx.len && is_ws ctx.s.[ctx.pos] do
    ctx.pos <- ctx.pos + 1
  done

let expect ctx ch =
  skip_ws ctx;
  if ctx.pos >= ctx.len || ctx.s.[ctx.pos] <> ch then failwith "Invalid JSON line";
  ctx.pos <- ctx.pos + 1

let take_string ctx =
  expect ctx '"';
  let buf = Buffer.create 32 in
  let rec loop () =
    if ctx.pos >= ctx.len then failwith "Unterminated JSON string";
    let c = ctx.s.[ctx.pos] in
    ctx.pos <- ctx.pos + 1;
    match c with
    | '"' -> Buffer.contents buf
    | '\\' ->
        if ctx.pos >= ctx.len then failwith "Invalid JSON escape";
        let escaped = ctx.s.[ctx.pos] in
        ctx.pos <- ctx.pos + 1;
        Buffer.add_char buf
          (match escaped with
           | '"' -> '"'
           | '\\' -> '\\'
           | '/' -> '/'
           | 'n' -> '\n'
           | 'r' -> '\r'
           | 't' -> '\t'
           | other -> other);
        loop ()
    | other ->
        Buffer.add_char buf other;
        loop ()
  in
  loop ()

let take_number ctx =
  skip_ws ctx;
  let start = ctx.pos in
  while
    ctx.pos < ctx.len
    &&
    match ctx.s.[ctx.pos] with
    | '0' .. '9' | '-' | '+' | '.' | 'e' | 'E' -> true
    | _ -> false
  do
    ctx.pos <- ctx.pos + 1
  done;
  if ctx.pos = start then failwith "Expected JSON number";
  String.sub ctx.s start (ctx.pos - start)

let take_literal ctx literal =
  let n = String.length literal in
  if ctx.pos + n > ctx.len || String.sub ctx.s ctx.pos n <> literal then
    failwith "Invalid JSON literal";
  ctx.pos <- ctx.pos + n

let take_scalar ctx =
  skip_ws ctx;
  if ctx.pos >= ctx.len then failwith "Expected JSON value";
  match ctx.s.[ctx.pos] with
  | '"' -> JString (take_string ctx)
  | 'n' ->
      take_literal ctx "null";
      JNull
  | '-' | '0' .. '9' -> JNumber (take_number ctx)
  | _ -> failwith "Unsupported JSON value"

let parse_flat_object parse_value line =
  let ctx = make_ctx line in
  expect ctx '{';
  let rec fields acc =
    skip_ws ctx;
    if ctx.pos < ctx.len && ctx.s.[ctx.pos] = '}' then begin
      ctx.pos <- ctx.pos + 1;
      List.rev acc
    end else begin
      let key = take_string ctx in
      expect ctx ':';
      let value = parse_value ctx in
      skip_ws ctx;
      if ctx.pos < ctx.len && ctx.s.[ctx.pos] = ',' then begin
        ctx.pos <- ctx.pos + 1;
        fields ((key, value) :: acc)
      end else begin
        expect ctx '}';
        List.rev ((key, value) :: acc)
      end
    end
  in
  fields []

let parse_schema_line line =
  let ctx = make_ctx line in
  expect ctx '{';
  let key = take_string ctx in
  if key <> "__schema__" then failwith "First JSONL line must contain __schema__";
  expect ctx ':';
  let schema_pairs = parse_flat_object (fun ctx -> JString (take_string ctx)) (String.sub ctx.s ctx.pos (ctx.len - ctx.pos)) in
  List.map
    (function
      | name, JString dtype -> (name, parse_type dtype)
      | _ -> failwith "Invalid schema value")
    schema_pairs

let cell_of_scalar expected_type = function
  | JNull -> VNull
  | JString s -> parse_cell expected_type s
  | JNumber n -> parse_cell expected_type n

let read_json_with_schema filename =
  let ic = open_in filename in
  let schema_line =
    try input_line ic
    with End_of_file ->
      close_in ic;
      failwith "Empty JSONL file"
  in
  let schema = parse_schema_line schema_line in

  let parse_row line =
    let values = parse_flat_object take_scalar line in
    List.map
      (fun (col_name, col_type) ->
        let cell =
          match List.assoc_opt col_name values with
          | Some scalar -> cell_of_scalar col_type scalar
          | None -> VNull
        in
        (col_name, cell))
      schema
  in

  let rec next_row () =
      try
        let line = input_line ic in
        if String.trim line = "" then next_row ()
        else Some (parse_row line)
      with End_of_file ->
        close_in ic;
        None
  in

  let stream = Seq.of_dispenser next_row in
  (schema, stream)
