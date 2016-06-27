(* JsCoq/SerAPI
 * Copyright (C) 2016 Emilio Gallego / Mines ParisTech
 *
 * LICENSE: GPLv3+
 *)

(* Library management for Sertop_js

   Due to the large size of Coq libraries, we wnat to perform caching
   and lazy loading in the browser.
*)
open Jslib
open Lwt
open Js

let cma_verb     = false
let pkg_prefix   = ref ""
let coq_pkgs_dir = "coq-pkgs/"

(* Main file_cache, indexed by url*)
type cache_entry = {
  file_content : string  ; (* file_content is backed by a TypedArray, thanks to @hhugo *)
  md5          : Digest.t;
}

(* Number of actual files in a full distribution ~ 2000 *)
let file_cache : (string, cache_entry) Hashtbl.t = Hashtbl.create 503

(* The cma resolver cache maps a cma module to its actual path. *)
let cma_cache : (string, string) Hashtbl.t = Hashtbl.create 103

let preload_vo_file ?(refresh=false) base_url (file, _hash) : unit Lwt.t =
  let open XmlHttpRequest                           in
  let full_url    = base_url  ^ "/" ^ file          in
  let request_url = !pkg_prefix ^ full_url          in
  let cached      = Hashtbl.mem file_cache full_url in

  (* Only reload if not cached or a refresh is requested *)
  if not cached || refresh then begin
  perform_raw ~response_type:ArrayBuffer request_url >>= fun frame ->
  (* frame.code contains the request status *)
  (* Is this redudant with the Opt check? I guess so *)
  if frame.code = 200 || frame.code = 0 then
    Js.Opt.case
      frame.content
      (fun ()        -> ())
      (fun raw_array ->
         let cache_entry = {
           file_content = Typed_array.String.of_arrayBuffer raw_array;
           md5          = Digest.string "";
         } in
         Hashtbl.add file_cache full_url cache_entry
      );
  Lwt.return_unit
  end
  else Lwt.return_unit

(* We grab the `cma/cmo`.js version of the module, we also add it
   to the path resolution cache: *)
let preload_cma_file base_url (file, _hash) : unit Lwt.t =
  let js_file = file ^ ".js"                in
  preload_vo_file base_url (js_file, _hash) >>= fun () ->
  if cma_verb then Format.eprintf "pre-loading cma file (%s, %s)\n%!" base_url js_file;
  Hashtbl.add cma_cache file base_url;
  Lwt.return_unit

(* XXX: Hack *)
let jslib_add_load_path pkg pkg_path has_ml =
  let open Names                                                       in
  let coq_path = DirPath.make @@ List.rev @@ List.map Id.of_string pkg in
  Loadpath.add_load_path ("./" ^ pkg_path) coq_path ~implicit:false;
  if has_ml then Mltop.add_ml_dir pkg_path

let preload_pkg _bundle pkg : unit Lwt.t =
  let pkg_dir = to_dir pkg                                           in
  let ncma    = List.length pkg.cma_files                            in
  let _nfiles = no_files pkg                                         in
  let preload_vo_and_log _nc _i f =
    preload_vo_file pkg_dir f >>= fun () ->
    (* !cb.pkg_progress (mk_progressInfo bundle pkg (i+nc+1)); *)
    Lwt.return_unit
  in
  Lwt_list.iter_s (preload_cma_file pkg_dir) pkg.cma_files    >>= fun () ->
  Lwt_list.iteri_s (preload_vo_and_log ncma) pkg.vo_files     >>= fun () ->
  jslib_add_load_path pkg.pkg_id pkg_dir (ncma > 0);
  (* !cb.pkg_load (mk_progressInfo bundle pkg nfiles); *)
  Lwt.return_unit

(* Load a bundle *)
let rec preload_from_file file =
  let file_url = !pkg_prefix ^ file ^ ".json" in
  XmlHttpRequest.get file_url >>= (fun res ->
  (* XXX: Use _JSON.json??????? *)
  let bundle = try Jslib.json_to_bundle
                     (Yojson.Basic.from_string res.XmlHttpRequest.content)
               with | _ -> (Format.eprintf "JSON error in preload_from_file\n%!";
                            raise (Failure "JSON"))
  in
  (* !cb.bundle_start bundle_info; *)
  (* Load deps *)
  Lwt_list.iter_p  preload_from_file bundle.deps <&>
  Lwt_list.iter_p (preload_pkg file) bundle.pkgs >>= fun () ->
  (* !cb.bundle_load  bundle_info; *)
  return_unit)

let iter_arr (f : 'a -> unit Lwt.t) (l : 'a js_array t) : unit Lwt.t =
  let f_js = wrap_callback (fun p x _ _ -> f x >>= (fun () -> p)) in
  l##(reduce_init f_js return_unit)

(*
let info_from_file file =
  let file_url = !pkg_prefix ^ file ^ ".json" in
  XmlHttpRequest.get file_url >>= fun res ->
  let bundle = try Jslib.json_to_bundle
                     (Yojson.Basic.from_string res.XmlHttpRequest.content)
               with | _ -> (Format.eprintf "JSON error in preload_from_file\n%!";
                            raise (Failure "JSON"))
  in
  return @@ !cb.bundle_info (build_bundle_info bundle)
*)

let init base_path _all_pkgs init_pkgs =
  pkg_prefix := to_string base_path ^ "/" ^ coq_pkgs_dir;
  Lwt.async (fun () ->
    (* iter_arr (fun x -> to_string x |> info_from_file)                all_pkgs  >>= fun () -> *)
    iter_arr (fun x -> to_string x |> preload_from_file) init_pkgs >>= fun () ->
    return_unit
  )

let load_pkg pkg_file = Lwt.async (fun () ->
    preload_from_file pkg_file >>= fun () ->
    (* XXX: No notification for bundle loading *)
    (* !cb.bundle_load pkg_file; *)
    return_unit
  )

(* let _is_bad_url _ = false *)

(* XXX: Wait until we have enough UI support for logging *)
let coq_vo_req url =
  (* Format.eprintf "file %s requested\n%!" (to_string url); (\* with category info *\) *)
  (* if not @@ is_bad_url url then *)
  try let c_entry = Hashtbl.find file_cache url in
    (* Jslog.printf Jslog.jscoq_log "coq_resource_req %s\n%!" (Js.to_string url); *)
    Some c_entry.file_content
  with
    (* coq_vo_reg is also invoked throught the Sys.file_exists call
     * in mltop:file_of_name function, a good example on how to be
     * too smart for your own good $:-)
     *
     * Sadly coq only uses this information to determine if it will
     * load a cmo/cma file, not to guess the path...
     *)
  | Not_found ->
    (* We check vs the true filesystem, even if unfortunately the
       cache has to be used in coq_cma_req below :(

       Maybe we can fix this pitfall for 8.7 :/
    *)
    (* Format.eprintf "check path %s\n%!" url; *)
    if Filename.(check_suffix url "cma" || check_suffix url "cmo") then
      let js_file = (url ^ ".js")    in
      (* Format.eprintf "trying %s\n%!" js_file; *)
      try let c_entry = Hashtbl.find file_cache js_file in
        Some c_entry.file_content
      with Not_found -> None
    else None

let coq_cma_link cma =
  let open Format in
  if cma_verb then eprintf "bytecode file %s requested\n%!" cma;
  try
    let cma_path = Hashtbl.find cma_cache cma  in
    (* Now, the js file should be in the file cache *)
    let js_file = cma_path ^ "/" ^ cma ^ ".js" in
    if cma_verb then eprintf "requesting load of %s\n%!" js_file;
    try
      let js_code = (Hashtbl.find file_cache js_file).file_content in
      (* When eval'ed, the js_code will return a closure waiting for the
         jsoo global object to link the plugin.
      *)
      Js.Unsafe.((eval_string js_code : < .. > Js.t -> unit) global)
    with
    | Not_found ->
      eprintf "cache inconsistecy for %s !! \n%!" cma;
  with
  | Not_found ->
    eprintf "!! bytecode file %s not found in path\n%!" cma
