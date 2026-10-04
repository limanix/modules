# Platform and generic harness regressions use the same public test ABI.
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
