# Require releases.nix to cover exactly the version lines in module.toml.
name: lines: releases:
let
  require =
    condition: message: if condition then true else throw "Module catalog: ${name}: ${message}";
in
assert require (builtins.isAttrs releases) "releases.nix must be an attribute set of lines";
require (
  builtins.sort builtins.lessThan (builtins.attrNames releases)
  == builtins.sort builtins.lessThan lines
) "releases.nix must map exactly the lines that module.toml declares"
