# Check every public schema at the root of catalog/_shared.
#
# shared-files.nix provides the list, without test.nix or private helpers.
# Each file is evaluated on its own by shared-declarations.nix.
# Its imports and option declarations must follow the shared schema rules.
# common.nix includes this check in the platform suite.
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
