open Cmdliner

let help =
  [ `S Manpage.s_common_options
  ; `P "These options are common to all commands."
  ; `S "MORE HELP"
  ; `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command."
  ; `Noblank
  ; `S Manpage.s_bugs
  ; `P "Check bug reports at https://github.com/plugandtrade/ingtester." ]

let default_cmd =
  let doc = "Kubernetes Ingress testing" in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let man = help in
  ( (let open Term in
    ret (const (`Help (`Pager, None))))
  , Term.info "ingtester" ~version:"0.0" ~doc ~sdocs ~exits ~man )

let run dir = Lwt_main.run (Doctest.run_dir dir)

let cmd =
  let dir =
    let doc = "run test in directory" in
    Arg.(value & (opt string "./" & (info ["d"; "dir"] ~docv:"DIR" ~doc)))
  in Term.(const run $ dir) , Term.info "test" ~doc:"run test doc" ~sdocs:Manpage.s_common_options ~exits:Term.default_exits ~man:help

let cmds = [cmd]

let () = Term.(exit @@ eval_choice default_cmd cmds)
