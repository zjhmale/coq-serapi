open Sexplib.Std

open Ser_constrexpr
open Ser_glob_term

type glob_constr_and_expr =
  [%import: Tactypes.glob_constr_and_expr
  [@with
     Glob_term.glob_constr  := glob_constr;
     Constrexpr.constr_expr := constr_expr;
  ]]
  [@@deriving sexp]
