# Root shared schemas cannot import application or private test modules.
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
