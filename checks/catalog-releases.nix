# Check that releases.nix covers exactly the declared version lines.
#
# catalog.nix passes the lines from module.toml and the release records here.
# Missing or extra lines are rejected before module evaluation.
# Package source details are checked by the source resolver, not by this file.
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
