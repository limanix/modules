# Collect checks for the public interface and the test harness itself.
#
# modules.nix loads this file for the platform suite.
# The eval cases test catalog rules, shared schemas, imports, and ownership.
# The fails cases check invalid interface settings.
# The run case checks the permissions of the Nix build process.
# This file uses the same eval, fails, and run groups as a module's test.nix.
{
  evalSystem,
  pkgs,
  lib,
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  catalog = import ./catalog.nix ../catalog;
  interface = import ./interface-tests.nix { inherit evalSystem pkgs lib; };
in
{
  eval = interface.eval // {
    catalog = builtins.deepSeq catalog true;
    catalogMetadata = import ./catalog-tests.nix { inherit lib; };
    catalogLayout = import ./catalog-layout-tests.nix { inherit lib; };
    testABI = import ./test-contract-tests.nix { inherit lib system; };
    buildPolicy = import ./build-policy-tests.nix { inherit lib system; };
    sharedSchemas = import ./shared.nix { inherit pkgs lib; };
    sharedDeclarations = import ./shared-tests.nix { inherit pkgs lib; };
    declarationOwnership = import ./ownership-tests.nix { inherit lib; };
    importBoundaries = import ./imports-tests.nix { inherit lib; };
  };
  inherit (interface) fails;
  run.builderPermissions = import ./builder-permissions.nix { inherit pkgs; };
}
