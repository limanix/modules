{ pkgs, lib }:
let
  files = import ./shared-files.nix;
  checkFile =
    path:
    import ./shared-declarations.nix {
      inherit lib pkgs;
      modules = [ path ];
    };
in
builtins.all checkFile files.public
