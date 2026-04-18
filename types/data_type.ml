type col_type =
  | TInt
  | TFloat
  | TString

type cell =
  | VInt of int
  | VFloat of float
  | VString of string
  | VNull

(* A schema maps column names to their expected data types *)
type schema = (string * col_type) list

(* A data object is a single row *)
type dataobject = (string * cell) list