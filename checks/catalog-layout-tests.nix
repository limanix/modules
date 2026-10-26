# Test catalog discovery with small example directory trees.
#
# The fixtures under fixtures/catalog-layout contain valid and invalid layouts.
# Modules below their kinds must be found with the correct names and paths.
# Duplicate names across kinds and modules outside kind directories must fail.
{ lib }:
let
  discover = import ./catalog.nix;
  fixture = name: ./fixtures/catalog-layout + "/${name}";
  rejects = name: !(builtins.tryEval (builtins.deepSeq (discover (fixture name)) true)).success;
  valid = discover (fixture "valid");
in
assert
  map (module: { inherit (module) name kind; }) valid == [
    {
      name = "alpha";
      kind = "shell";
    }
    {
      name = "beta";
      kind = "modules";
    }
  ];
assert builtins.all (
  module:
  baseNameOf (toString module.directory) == module.name
  && baseNameOf (dirOf (toString module.directory)) == module.kind
  && lib.hasSuffix "/${module.kind}/${module.name}/default.nix" (toString module.path)
) valid;
assert rejects "duplicate";
assert rejects "flat";
true
