(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(************************************************************************)
(* Coq serialization API/Plugin, batch compiler                         *)
(* Copyright 2016 MINES ParisTech                                       *)
(************************************************************************)
(* Status: Very Experimental                                            *)
(************************************************************************)

exception End_of_input

open Sexplib

(* open Ser_loc *)
open Ser_vernacexpr

type stats = {
  mutable specs  : int;
  mutable proofs : int;
  mutable misc   : int;
}

let stats = {
  specs  = 0;
  proofs = 0;
  misc   = 0;
}

(* XXX: Move to sertop_stats.ml *)
let do_stats =
  let proof_loc = ref None in
  fun (loc : Loc.t) (vrn : Vernacexpr.vernac_expr) ->
  let open Vernacexpr in
  let incS (l : Loc.t) f =
    let n_lines = Loc.(l.line_nb_last - l.line_nb + 1) in
    Format.eprintf "Adding %d lines @\n%!" n_lines;
    f + n_lines
  in
  match vrn with
  (* Definition *)
  | VernacDefinition (_,_,_)
  | VernacFixpoint   (_,_)
  | VernacInductive  (_,_,_)
  | VernacCoFixpoint (_,_)
  | VernacNotation   (_,_,_,_)      -> stats.specs <- incS loc stats.specs

  (* Proofs *)
  | VernacGoal _
  | VernacStartTheoremProof (_,_,_) -> stats.specs <- incS loc stats.specs;
                                       proof_loc := Some Loc.(loc.line_nb_last)
  | VernacProof (_,_)               -> ()
  (* XXX: Should we use the +1 rule here, what happens for proofs:
     Proof. exact: L. Qed.
   *)
  | VernacEndProof _                -> Option.iter (fun ll ->
                                         stats.proofs <- stats.proofs + (Loc.(loc.line_nb) - ll) + 1
                                       ) !proof_loc;
                                       proof_loc := None
  (* This is tricky.. *)
  (* This is Ltac := ... *)
  | VernacExtend (("VernacDeclareTacticDefinition",_),_)
                                    -> stats.proofs <- incS loc stats.proofs;

  | _                               -> if Option.is_empty !proof_loc then stats.misc <- incS loc stats.misc

(*
  match vrn with
  | VernacLoad (_,_) -> (??)
  | VernacTime _ -> (??)
  | VernacRedirect (_,_) -> (??)
  | VernacTimeout (_,_) -> (??)
  | VernacFail _ -> (??)
  | VernacError _ -> (??)
  | VernacSyntaxExtension (_,_) -> (??)
  | VernacOpenCloseScope (_,_) -> (??)
  | VernacDelimiters (_,_) -> (??)
  | VernacBindScope (_,_) -> (??)
  | VernacInfix (_,_,_,_) -> (??)
  | VernacNotationAddFormat (_,_,_) -> (??)
  | VernacStartTheoremProof (_,_,_) -> (??)
  | VernacExactProof _ -> (??)
  | VernacAssumption (_,_,_) -> (??)
  | VernacScheme _ -> (??)
  | VernacCombinedScheme (_,_) -> (??)
  | VernacUniverse _ -> (??)
  | VernacConstraint _ -> (??)
  | VernacBeginSection _ -> (??)
  | VernacEndSegment _ -> (??)
  | VernacRequire (_,_,_) -> (??)
  | VernacImport (_,_) -> (??)
  | VernacCanonical _ -> (??)
  | VernacCoercion (_,_,_,_) -> (??)
  | VernacIdentityCoercion (_,_,_,_) -> (??)
  | VernacNameSectionHypSet (_,_) -> (??)
  | VernacInstance (_,_,_,_,_) -> (??)
  | VernacContext _ -> (??)
  | VernacDeclareInstances (_,_) -> (??)
  | VernacDeclareClass _ -> (??)
  | VernacDeclareModule (_,_,_,_) -> (??)
  | VernacDefineModule (_,_,_,_,_) -> (??)
  | VernacDeclareModuleType (_,_,_,_) -> (??)
  | VernacInclude _ -> (??)
  | VernacSolveExistential (_,_) -> (??)
  | VernacAddLoadPath (_,_,_) -> (??)
  | VernacRemoveLoadPath _ -> (??)
  | VernacAddMLPath (_,_) -> (??)
  | VernacDeclareMLModule _ -> (??)
  | VernacChdir _ -> (??)
  | VernacWriteState _ -> (??)
  | VernacRestoreState _ -> (??)
  | VernacResetName _ -> (??)
  | VernacResetInitial  -> (??)
  | VernacBack _ -> (??)
  | VernacBackTo _ -> (??)
  | VernacCreateHintDb (_,_) -> (??)
  | VernacRemoveHints (_,_) -> (??)
  | VernacHints (_,_,_) -> (??)
  | VernacSyntacticDefinition (_,_,_,_) -> (??)
  | VernacDeclareImplicits (_,_) -> (??)
  | VernacArguments (_,_,_,_) -> (??)
  | VernacArgumentsScope (_,_) -> (??)
  | VernacReserve _ -> (??)
  | VernacGeneralizable _ -> (??)
  | VernacSetOpacity _ -> (??)
  | VernacSetStrategy _ -> (??)
  | VernacUnsetOption _ -> (??)
  | VernacSetOption (_,_) -> (??)
  | VernacAddOption (_,_) -> (??)
  | VernacRemoveOption (_,_) -> (??)
  | VernacMemOption (_,_) -> (??)
  | VernacPrintOption _ -> (??)
  | VernacCheckMayEval (_,_,_) -> (??)
  | VernacGlobalCheck _ -> (??)
  | VernacDeclareReduction (_,_) -> (??)
  | VernacPrint _ -> (??)
  | VernacSearch (_,_,_) -> (??)
  | VernacLocate _ -> (??)
  | VernacRegister (_,_) -> (??)
  | VernacComments _ -> (??)
  | VernacStm _ -> (??)
  | VernacAbort _ -> (??)
  | VernacAbortAll  -> (??)
  | VernacRestart  -> (??)
  | VernacUndo _ -> (??)
  | VernacUndoTo _ -> (??)
  | VernacBacktrack (_,_,_) -> (??)
  | VernacFocus _ -> (??)
  | VernacUnfocus  -> (??)
  | VernacUnfocused  -> (??)
  | VernacBullet _ -> (??)
  | VernacProgram _ -> (??)
  | VernacSubproof _ -> (??)
  | VernacEndSubproof  -> (??)
  | VernacShow _ -> (??)
  | VernacCheckGuard  -> (??)
  | VernacProofMode _ -> (??)
  | VernacToplevelControl _ -> (??)
  | VernacExtend (_,_) -> (??)
  | VernacPolymorphic (_,_) -> (??)
  | VernacLocal (_,_) -> (??)
*)

let parse_sentence = Flags.with_option Flags.we_are_parsing
  (fun pa ->
    match Pcoq.Gram.entry_parse Pcoq.main_entry pa with
    | Some (loc, ast) -> loc, ast
    | None            -> raise End_of_input
  )

let process_vernac (loc : Loc.t) (vrn : Vernacexpr.vernac_expr) =
  let open Sexp   in
  let open Format in
  Stm.interp false (loc, vrn);
  do_stats loc vrn;
  printf "@[%a@] @[%a@]@\n%!" (Pp.pp_with ?pp_tag:None) (Pp.pr_loc loc)
                               pp (sexp_of_vernac_expr vrn)

let parse_document in_pa =
  try while true do
      let loc, ast = parse_sentence in_pa in
      process_vernac loc ast
    done
  with any ->
    let (e, _info) = CErrors.push any in
    match e with
    | End_of_input -> ()
    | any          ->
      let (e, info) = CErrors.push any in
      Format.eprintf "%a@\n%!" (Pp.pp_with ?pp_tag:None) (CErrors.iprint (e, info))

 (* Format.eprintf "Error in parsing@\n%!" (\* XXX: add loc *\) *)

(* XXX Reuse sertop_init *)

let coq_init coq_lib =

  Lib.init ();

  Goptions.set_string_option_value ["Default";"Proof";"Mode"] "Classic";
  Global.set_engagement Declarations.PredicativeSet;
  Loadpath.add_load_path "." Nameops.default_root_prefix ~implicit:false;

  let ser_prelude_list coq_path =
    let mk_path prefix l = coq_path ^ "/" ^ prefix ^ "/" ^ String.concat "/" l in
    List.map (fun p -> ("Coq" :: p, mk_path "plugins"  p, true)) Sertop_prelude.coq_init_plugins  @
    List.map (fun p -> ("Coq" :: p, mk_path "theories" p, true)) Sertop_prelude.coq_init_theories
  in

  List.iter (fun (lib, lib_path, has_ml) ->
      let open Names in
      let coq_path = DirPath.make @@ List.rev @@ List.map Id.of_string lib in
      Loadpath.add_load_path lib_path coq_path ~implicit:true;
      if has_ml then Mltop.add_ml_dir lib_path
    ) (ser_prelude_list coq_lib);

  let sertop_dp = Names.DirPath.make [Names.Id.of_string "SerComp"] in
  Declaremods.start_library sertop_dp;

  List.iter (fun (dp, p, in_exp) ->
      Library.require_library_from_dirpath [dp,p] in_exp
    ) [Sertop_prelude.coq_prelude_mod coq_lib];

  Stm.init ();

  ()

let close_document () =
  let open Format in
  printf "Statistics:@\nSpecs:  %d@\nProofs: %d@\nMisc:   %d@\n%!" stats.specs stats.proofs stats.misc

open Cmdliner

let prelude =
  let doc = "Load prelude from COQPATH; plugins/ and theories/ should live there." in
  Arg.(required & opt (some string) Coq_config.coqlib & info ["prelude"] ~docv:"COQPATH" ~doc)

let input_file =
  let doc = "Input .v file." in
  Arg.(value & pos 0 string "" & info [] ~doc)

(* XXX Reuse sertop_args *)
let sercomp coq_lib in_file =
  let in_chan = open_in in_file            in
  CLexer.set_current_file ~fname:in_file;
  let in_strm = Stream.of_channel in_chan  in
  let in_pa   = Pcoq.Gram.parsable in_strm in
  (try
     coq_init coq_lib
   with any ->
     let (e, info) = CErrors.push any in
     Format.eprintf "%a@\n%!" (Pp.pp_with ?pp_tag:None) (CErrors.iprint (e, info))
  );
  parse_document in_pa;
  close_in in_chan;
  close_document ()

let sercomp_version = ".0000"

let sertop_cmd =
  let doc = "SerComp Coq Compiler" in
  let man = [
    `S "DESCRIPTION";
    `P "Experimental Coq Compiler with serialization support"
  ]
  in
  Term.(const sercomp $ prelude $ input_file ),
  Term.info "sertop" ~version:sercomp_version ~doc ~man

let main () =
  match Term.eval sertop_cmd with
  | `Error _ -> exit 1
  | _        -> exit 0

let _ = main ()
