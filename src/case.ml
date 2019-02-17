exception UnitParseError of string

module Parser = struct
  open Angstrom

  let is_separator = function ':' -> true | _ -> false

  let is_whitespace = function ' ' | '\t' -> true | _ -> false

  let is_comment = function '#' -> true | _ -> false

  let tokens (t1, t2) = Angstrom.(string t1 <|> string t2) <* skip is_separator

  let spaces = skip_while is_whitespace

  let comments = skip_while is_comment

  let lex p = p <* spaces

  let parse ts file =
    let p =
      comments *> spaces
      *> lift2
           (fun key value -> (key, value))
           (lex (tokens ts))
           (lex (take_till is_comment))
    in
    Angstrom.parse_string (lift (fun l -> l) (many p)) file
end

module Assertion = struct
  type t = Assert of string | Refute of string

  let to_bool = function Assert _ -> true | Refute _ -> false

  let of_tuple = function
    | "assert", p -> Some (Assert p)
    | "refute", p -> Some (Refute p)
    | _ -> None

  let of_tuple_exn (a, p) =
    match of_tuple (a, p) with
    | Some ass -> ass
    | None -> failwith (Format.sprintf "Unknown assertion: %s" a)

  let unpack = function Assert p -> p | Refute p -> p

  let pp = function
    | Assert s -> Format.sprintf "Should match: %s" s
    | Refute s -> Format.sprintf "Should not match: %s" s
end

module NginxLocation = struct
  type t = {path: string; matcher: Pcre.regexp}

  let make ?(flags = [`CASELESS]) path =
    {path; matcher= Pcre.regexp ~flags path}

  let match_ s t = Pcre.pmatch ~rex:t.matcher s

  let pp t = Format.sprintf "location ~* \"%s\"" t.path
end

module UnitTest = struct
  type t = {ingress: Ingress.t; assertions: Assertion.t list}

  let make ~ingress ~assertions = {ingress; assertions}

  let of_file ~file =
    let open Lwt.Infix in
    Lwt_io.with_file ~mode:Lwt_io.Input file (fun channel ->
        let ingress =
          match Ingress.of_yaml_file file with
          | Ok i -> i
          | Error e -> failwith (Format.sprintf "ooops %s" e)
        in
        let stream =
          Lwt_stream.filter (fun s -> s.[0] == '#') (Lwt_io.read_lines channel)
        in
        Lwt_stream.fold ( ^ ) stream ""
        >|= Parser.parse ("assert", "refute")
        >|= function
        | Ok p ->
            Ok (make ~ingress ~assertions:(List.map Assertion.of_tuple_exn p))
        | Error e -> Error e )

  let to_test {ingress; assertions} =
    let paths = Ingress.paths ingress in
    let tests =
      List.map
        (fun ass ->
          let maybe_path =
            List.find_opt
              (fun (p : Ingress.Rule.HttpRule.Path.t) ->
                let loc = NginxLocation.make p.path in
                NginxLocation.match_ (Assertion.unpack ass) loc )
              paths
          in
          let actual, msg =
            match maybe_path with
            | Some path -> (true, Ingress.PP.path path)
            | None -> (false, "No matches")
          in
          ( Assertion.pp ass
          , `Quick
          , fun () -> Alcotest.(check bool) msg (Assertion.to_bool ass) actual
          ) )
        assertions
    in
    (Ingress.pp ingress, tests)
end

let make file =
  let open Lwt.Infix in
  UnitTest.of_file ~file
  >|= function
  | Ok test ->
      Ok
        (Format.sprintf "[INGTESTER] (ingress): %s" file, UnitTest.to_test test)
  | Error e -> Error e

let run file =
  let open Lwt.Infix in
  make file
  >|= function
  | Ok (msg, test) -> Alcotest.run msg [test]
  | Error e -> print_endline (Format.sprintf "Run to run %s with %s" file e)

let run_dir dir =
  let open Lwt.Infix in
  let make_from_file file =
    make file >|= function Ok (_msg, t) -> t | Error e -> failwith e
  in
  let make_runner =
    Alcotest.run (Format.sprintf "INGTESTER root-dir: %s" dir)
  in
  let files = Fs.dir_contents dir (Pcre.regexp "(.?)?ingress\\.(yml|yaml)") in
  Lwt_list.map_s make_from_file files >|= make_runner
