(* io/json_reader.ml *)
open Data_type

let parse_type s =
  let s_clean = String.lowercase_ascii (String.trim s) in
  match s_clean with
  | "int"   -> TInt
  | "float" -> TFloat
  | _       -> TString

let parse_cell expected_type str_val =
  let s = String.trim str_val in
  if s = "" then VNull
  else try
    match expected_type with
    | TInt    -> VInt (int_of_string s)
    | TFloat  -> VFloat (float_of_string s)
    | TString -> VString s
  with Failure _ -> VNull

type json_value =
  | JObject of (string * json_value) list
  | JArray  of json_value list
  | JString of string
  | JNumber of float
  | JBool   of bool
  | JNull

let is_ws = function ' ' | '\n' | '\r' | '\t' -> true | _ -> false
type ctx = { s : string; len : int; mutable pos : int }
let make_ctx s = { s; len = String.length s; pos = 0 }

let ctx_skip ctx =
  while ctx.pos < ctx.len && is_ws ctx.s.[ctx.pos] do ctx.pos <- ctx.pos + 1 done

let ctx_expect ctx ch =
  ctx_skip ctx;
  if ctx.pos >= ctx.len || ctx.s.[ctx.pos] <> ch then failwith "Parse error";
  ctx.pos <- ctx.pos + 1

let ctx_take_str ctx =
  ctx_expect ctx '"';
  let buf = Buffer.create 32 in
  let rec go () =
    let c = ctx.s.[ctx.pos] in
    ctx.pos <- ctx.pos + 1;
    match c with
    | '"' -> Buffer.contents buf
    | '\\' ->
        let e = ctx.s.[ctx.pos] in ctx.pos <- ctx.pos + 1;
        Buffer.add_char buf (match e with | 'n' -> '\n' | 't' -> '\t' | c -> c);
        go ()
    | c -> Buffer.add_char buf c; go ()
  in go ()

let ctx_take_number ctx =
  let start = ctx.pos in
  while ctx.pos < ctx.len &&
    (match ctx.s.[ctx.pos] with '0'..'9' | '-' | '+' | '.' | 'e' | 'E' -> true | _ -> false)
  do ctx.pos <- ctx.pos + 1 done;
  float_of_string (String.sub ctx.s start (ctx.pos - start))

let rec ctx_parse_value ctx =
  ctx_skip ctx;
  match ctx.s.[ctx.pos] with
  | '{' -> ctx.pos <- ctx.pos + 1; ctx_parse_object ctx
  | '[' -> ctx.pos <- ctx.pos + 1; ctx_parse_array ctx
  | '"' -> JString (ctx_take_str ctx)
  | 't' -> ctx.pos <- ctx.pos + 4; JBool true
  | 'f' -> ctx.pos <- ctx.pos + 5; JBool false
  | 'n' -> ctx.pos <- ctx.pos + 4; JNull
  | '-' | '0'..'9' -> JNumber (ctx_take_number ctx)
  | _ -> failwith "Unexpected JSON char"

and ctx_parse_array ctx =
  let acc = ref [] in
  ctx_skip ctx;
  if ctx.pos < ctx.len && ctx.s.[ctx.pos] = ']' then (ctx.pos <- ctx.pos + 1; JArray [])
  else begin
    let more = ref true in
    while !more do
      acc := ctx_parse_value ctx :: !acc; ctx_skip ctx;
      if ctx.pos < ctx.len && ctx.s.[ctx.pos] = ',' then ctx.pos <- ctx.pos + 1 else more := false
    done;
    ctx_expect ctx ']'; JArray (List.rev !acc)
  end

and ctx_parse_object ctx =
  let acc = ref [] in
  ctx_skip ctx;
  if ctx.pos < ctx.len && ctx.s.[ctx.pos] = '}' then (ctx.pos <- ctx.pos + 1; JObject [])
  else begin
    let more = ref true in
    while !more do
      ctx_skip ctx; let key = ctx_take_str ctx in ctx_expect ctx ':';
      let v = ctx_parse_value ctx in acc := (key, v) :: !acc; ctx_skip ctx;
      if ctx.pos < ctx.len && ctx.s.[ctx.pos] = ',' then ctx.pos <- ctx.pos + 1 else more := false
    done;
    ctx_expect ctx '}'; JObject (List.rev !acc)
  end

let parse_json_cell expected_type = function
  | JNull -> VNull
  | JString s -> parse_cell expected_type s
  | JNumber n ->
      (match expected_type with
       | TInt -> VInt (int_of_float n)
       | TFloat -> VFloat n
       | TString -> VString (string_of_float n))
  | JBool b -> (match expected_type with TString -> VString (string_of_bool b) | _ -> VNull)
  | _ -> VNull

let ctx_take_str_array ctx =
  ctx_expect ctx '['; let acc = ref [] in ctx_skip ctx;
  if ctx.pos < ctx.len && ctx.s.[ctx.pos] <> ']' then begin
    acc := [ctx_take_str ctx]; ctx_skip ctx;
    while ctx.pos < ctx.len && ctx.s.[ctx.pos] = ',' do
      ctx.pos <- ctx.pos + 1; acc := ctx_take_str ctx :: !acc; ctx_skip ctx
    done
  end;
  ctx_expect ctx ']'; List.rev !acc

let read_json_with_schema filename =
  let ic = open_in filename in
  let len = in_channel_length ic in
  let content = really_input_string ic len in
  close_in ic;
  let ctx = make_ctx content in

  ctx_expect ctx '{';
  let cols = ref [] in let dtypes = ref [] in let in_data = ref false in

  ctx_skip ctx;
  while not !in_data && ctx.pos < ctx.len && ctx.s.[ctx.pos] <> '}' do
    let key = ctx_take_str ctx in ctx_expect ctx ':'; ctx_skip ctx;
    match key with
    | "columns" ->
        cols := ctx_take_str_array ctx; ctx_skip ctx;
        if ctx.pos < ctx.len && ctx.s.[ctx.pos] = ',' then ctx.pos <- ctx.pos + 1
    | "datatypes" ->
        dtypes := List.map parse_type (ctx_take_str_array ctx); ctx_skip ctx;
        if ctx.pos < ctx.len && ctx.s.[ctx.pos] = ',' then ctx.pos <- ctx.pos + 1
    | "data" -> ctx_expect ctx '['; in_data := true
    | _ -> ignore (ctx_parse_value ctx); ctx_skip ctx;
        if ctx.pos < ctx.len && ctx.s.[ctx.pos] = ',' then ctx.pos <- ctx.pos + 1
  done;

  let schema = List.combine !cols !dtypes in

  let parse_row () =
    match ctx_parse_value ctx with
    | JArray vals ->
        let rec zip_row sch v acc =
          match sch, v with
          | [], _ | _, [] -> List.rev acc
          | (name, dtype) :: st, x :: xt -> zip_row st xt ((name, parse_json_cell dtype x) :: acc)
        in zip_row schema vals []
    | _ -> failwith "Data row must be array"
  in

  let done_ = ref false in
  let stream = Seq.of_dispenser (fun () ->
    if !done_ then None
    else begin
      ctx_skip ctx;
      if ctx.pos >= ctx.len || ctx.s.[ctx.pos] = ']' then (done_ := true; None)
      else begin
        let row = parse_row () in ctx_skip ctx;
        if ctx.pos < ctx.len && ctx.s.[ctx.pos] = ',' then ctx.pos <- ctx.pos + 1;
        Some row
      end
    end
  ) in
  (schema, stream)