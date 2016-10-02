(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(************************************************************************)
(* Coq serialization API/Plugin                                         *)
(* Copyright 2016 MINES ParisTech                                       *)
(************************************************************************)
(* Status: Very Experimental                                            *)

type reified_goal = Constr.constr * Context.Compacted.Declaration.t list

val get_goals : Stateid.t -> reified_goal Proof.pre_goals option

(* type reified_egoal = Constrexpr.constr_expr * (Names.Id.t list * Constrexpr.constr_expr option * Constrexpr.constr_expr) list *)
type reified_egoal = Constrexpr.constr_expr * unit list

val get_egoals : Stateid.t -> reified_egoal Proof.pre_goals option

