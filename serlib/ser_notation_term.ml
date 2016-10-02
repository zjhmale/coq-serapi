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
(************************************************************************)

open Sexplib.Std

open Ser_loc
open Ser_flags
open Ser_names
open Ser_constrexpr
open Ser_tok
open Ser_extend

type notation_spec =
  [%import: Notation_term.notation_spec
  [@with
    Loc.located  := located;
  ]]
  [@@deriving sexp]

type syntax_modifier =
  [%import: Notation_term.syntax_modifier
  [@with
    Loc.located  := located;
    Flags.compat_version    := compat_version;
    Extend.gram_assoc       := gram_assoc;
    Extend.production_level := production_level;
    Extend.simple_constr_prod_entry_key := simple_constr_prod_entry_key;
  ]]
  [@@deriving sexp]

type grammar_constr_prod_item =
  [%import: Notation_term.grammar_constr_prod_item
  [@with
     Names.Id.t                   := id;
     Tok.t                        := tok;
     Extend.constr_prod_entry_key := constr_prod_entry_key;
  ]]
  [@@deriving sexp]

type notation_var_internalization_type =
  [%import: Notation_term.notation_var_internalization_type]
  [@@deriving sexp]

type notation_grammar =
  [%import: Notation_term.notation_grammar
  [@with
     Constrexpr.notation    := notation;
     Extend.gram_assoc      := gram_assoc;
  ]]
  [@@deriving sexp]

