open Sexplib.Std

open Ser_names
open Ser_constr

type context_compacted_declaration =
  [%import: Context.Compacted.Declaration.t
  [@with
     Names.Id.t                    := id;
     Constr.t                      := constr;
     Constr.constr                 := constr;
  ]]
  [@@deriving sexp]
