{
  paths,
}:
let
  checks = import ./default.nix;
  selected = builtins.fromJSON paths;
  inspect =
    path:
    let
      label = builtins.concatStringsSep "." path;
      value = builtins.foldl' (set: name: builtins.getAttr name set) checks path;
    in
    builtins.addErrorContext "while evaluating catalog check ${label}" (
      if builtins.isAttrs value then
        builtins.map (name: "group\t${builtins.toJSON (path ++ [ name ])}") (builtins.attrNames value)
      else
        builtins.seq (builtins.toJSON value) [ "passed\t${label}" ]
    );
in
{
  result = builtins.concatStringsSep "\n" (builtins.concatMap inspect selected);
}
