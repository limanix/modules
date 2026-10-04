{ lib }:
let
  validate = import ./catalog-metadata.nix;
  discover = import ./catalog-entries.nix;
  rejectsEntries = entries: !(builtins.tryEval (builtins.deepSeq (discover entries) true)).success;
  base = {
    description = "Fixture module.";
  };
  versions = base // {
    versions = [
      "1.10"
      "1.9"
    ];
    default = "1.10";
  };
  rejects =
    name: metadata: !(builtins.tryEval (builtins.deepSeq (validate name metadata) true)).success;
in
assert
  discover {
    fixture = "directory";
    _shared = "directory";
    ".DS_Store" = "regular";
    "README.md" = "regular";
    pins = "regular";
  } == [ "fixture" ];
assert discover { "fixture-1" = "directory"; } == [ "fixture-1" ];
assert rejectsEntries { fixture = "symlink"; };
assert rejectsEntries { fixture = "unknown"; };
assert validate "fixture-pod" base == { lines = [ ]; };
assert
  validate "fixture" versions == {
    lines = [
      "1.9"
      "1.10"
    ];
    default = "1.10";
  };
assert validate "fixture" (base // { versions = [ ]; }) == { lines = [ ]; };
assert builtins.all (name: rejects name base) [
  "_shared"
  "internal"
  "capabilities"
  "pins"
  "fixture-1"
  "Fixture"
  "fixture--pod"
  (lib.concatStrings (lib.replicate 64 "a"))
];
assert rejects "fixture" [ ];
assert rejects "fixture" { };
assert rejects "fixture" (base // { extra = true; });
assert rejects "fixture" (base // { description = " \n\t"; });
assert rejects "fixture" (base // { description = 1; });
assert rejects "fixture" (base // { default = ""; });
assert rejects "fixture" (base // { versions = "1"; });
assert rejects "fixture" (base // { versions = [ "1" ]; });
assert rejects "fixture" (versions // { default = "2"; });
assert rejects "fixture" (versions // { default = 1; });
assert rejects "fixture" (
  versions
  // {
    versions = [
      "1.9"
      "1.9"
    ];
    default = "1.9";
  }
);
assert builtins.all
  (
    line:
    rejects "fixture" (
      base
      // {
        versions = [ line ];
        default = line;
      }
    )
  )
  [
    1
    "v1"
    "1..2"
    "1-2"
    (lib.concatStrings (lib.replicate 64 "1"))
  ];
true
