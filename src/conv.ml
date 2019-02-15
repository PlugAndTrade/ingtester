let to_yojson (ezjson : Yaml.value) : Yojson.Safe.json =
  let rec fn = function
    | `Null -> `Null
    | `Bool b -> `Bool b
    | `Float f -> `Float f
    | `String value -> `String value
    | `A l -> `List (List.map fn l)
    | `O l -> `Assoc (List.map (fun (k, v) -> (k, fn v)) l)
  in
  fn ezjson
