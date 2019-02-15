module Annotations = struct
  type t = {use_regex: string option} [@@deriving yojson]
end

module Metadata = struct
  module Annotations = struct
    type t = {use_regex: string [@key "nginx.ingress.kubernetes.io/use-regex"][@default "false"]} [@@deriving yojson { strict = false}]
  end

  type t = {name: string; namespace: string [@default "default"]; annotations: Annotations.t}
  [@@deriving yojson { strict = false}]
end

module Rule = struct
  module HttpRule = struct
    module Backend = struct
      type t =
        { service_name: string [@key "serviceName"]
        ; service_port: int [@key "servicePort"] }
      [@@deriving yojson { strict = false}]
    end

    module Path = struct
      type t = {path: string; backend: Backend.t} [@@deriving yojson { strict = false}]
    end

    type t = {paths: Path.t list} [@@deriving yojson]
  end

  type t = {host: string; http: HttpRule.t} [@@deriving yojson { strict = false}]
end

module Spec = struct
  type t = {rules: Rule.t list} [@@deriving yojson { strict = false}]
end

type t =
  {api_version: string [@key "apiVersion"]; kind: string; metadata: Metadata.t}
[@@deriving yojson { strict = false}]

let of_json_file f = f |> Yojson.Safe.from_file |> of_yojson

let of_json j = j |> Yojson.Safe.from_string |> of_yojson

let of_yaml s =
  match Yaml.yaml_of_string s with
  | Ok y -> (
    match Yaml.to_json y with
    | Ok j -> j |> Conv.to_yojson |> of_yojson
    | Error (`Msg e) ->
        failwith (Format.sprintf "Yaml.to_json Failed with %s" e) )
  | Error (`Msg e) -> failwith (Format.sprintf "Failed with %s" e)

let of_yaml_file file =
  let yaml = Yaml_unix.of_file_exn (Fpath.v file) in
  yaml |> Conv.to_yojson |> of_yojson
