exception UnitParseError of string

module Parser = struct
  open Angstrom

  let is_separator = function | ':' -> true | _ -> false
  let is_whitespace = function | ' ' | '\t' -> true | _ -> false
  let is_comment = function | '#' -> true | _ -> false

  let tokens (t1, t2) = Angstrom.(string t1 <|>  string t2) <* skip is_separator
  let spaces = skip_while is_whitespace
  let comments = skip_while is_comment

  let lex p = p <* spaces

  let parse_comments ts file =
    let p =
     comments
     *> spaces
     *>
     (lift2(fun key value -> (key, value))
       (lex (tokens ts))
       (lex (take_till is_comment))
     ) in

  Angstrom.parse_string (lift (fun l -> l) (many p)) file
end
