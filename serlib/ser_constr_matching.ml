open Ser_names

type binding_bound_vars =
  [%import: Constr_matching.binding_bound_vars
  [@with
     Names.Id.Set.t := id_set;
  ]]
  [@@deriving sexp]
