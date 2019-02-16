let dir_contents dir rex =
  let rec traverse result = function
    | f::fs when Sys.is_directory f ->
          Sys.readdir f
          |> Array.to_list
          |> List.map (Filename.concat f)
          |> List.append fs
          |> traverse result
    | f::fs when Pcre.pmatch ~rex (Filename.extension f) -> traverse (f::result) fs
    | _f::fs -> traverse (result) fs
    | []    -> result
  in
    traverse [] [dir]
