# Validate shared option schemas without a complete NixOS system.
#
# The supplied modules are evaluated with lib.evalModules and the test packages.
# Every imported file must be a public schema listed by shared-files.nix.
# Application modules and private test helpers are rejected.
# Option declarations must also pass the ownership rules.
{
  lib,
  pkgs,
  modules,
}:
let
  files = import ./shared-files.nix;
  allowed = map toString files.public;
  checkGraph =
    graph:
    builtins.all (
      node:
      (
        builtins.elem (toString node.file) allowed
        || throw "Shared declarations import a non-schema module: ${node.file}"
      )
      && checkGraph node.imports
    ) graph;
  declarations = lib.evalModules {
    inherit modules;
    specialArgs = { inherit pkgs; };
  };
in
assert checkGraph declarations.graph;
assert import ./ownership.nix {
  inherit lib;
  inherit (declarations) options;
};

builtins.seq declarations.config true
