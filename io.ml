(* io.ml *)
open Types

(* --- PARSING LOGIC --- *)
let infer_type (s : string) : datatype =
  let s = String.trim s in
  if s = "" then VNull
  else
    match int_of_string_opt s with
    | Some i -> VInt i
    | None ->
        match float_of_string_opt s with
        | Some f -> VFloat f
        | None -> VString s

let parse_row (headers : string list) (line : string) : dataobject =
  let values = String.split_on_char ',' line in
  let rec zip hs vs acc =
    match hs, vs with
    | [], _ | _, [] -> List.rev acc
    | h::ht, v::vt -> zip ht vt ((String.trim h, infer_type v) :: acc)
  in
  zip headers values []

(* --- LAZY READING --- *)
let read_csv_lazy (filename : string) : dataobject Seq.t =
  let ic = open_in filename in
  
  (* Read first line for headers *)
  let header_line = try input_line ic with End_of_file -> "" in
  let headers = List.map String.trim (String.split_on_char ',' header_line) in
  
  if headers = [""] then Seq.empty
  else
    let raw_seq = Seq.of_dispenser (fun () ->
      try Some (input_line ic)
      with End_of_file -> 
        close_in ic; None
    ) in
    Seq.map (parse_row headers) raw_seq

(* --- WRITING LOGIC --- *)
let datatype_to_string = function
  | VInt i -> string_of_int i
  | VFloat f -> string_of_float f
  | VString s -> s
  | VNull -> ""

let write_csv (filename : string) (headers : string list) (seq : dataobject Seq.t) =
  let oc = open_out filename in
  (* Write headers *)
  output_string oc (String.concat "," headers ^ "\n");
  
  (* Write data lazily as it is consumed *)
  Seq.iter (fun row ->
    let row_strings = List.map (fun h -> 
      match List.assoc_opt h row with
      | Some v -> datatype_to_string v
      | None -> ""
    ) headers in
    output_string oc (String.concat "," row_strings ^ "\n")
  ) seq;
  close_out oc