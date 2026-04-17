(* types.ml *)

type datatype =
  | VInt of int
  | VFloat of float
  | VString of string
  | VNull

(* A dataobject is a single row represented as a list of (ColumnName, Value) *)
type dataobject = (string * datatype) list