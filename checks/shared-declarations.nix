{
  lib,
  pkgs,
  modules,
}:
let
  sharedPrefix = toString ../catalog/_shared + "/";
  checkGraph =
    graph:
    builtins.all (
      node:
      (
        lib.hasPrefix sharedPrefix node.file
        || throw "Shared declarations import an application module: ${node.file}"
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
# No NixOS application options are available here. A shared declaration that
# assigns packages, services or programs fails the module-system check.
builtins.seq declarations.config true
