{ lib }:
let
  check =
    modules:
    import ./ownership.nix {
      inherit lib;
      inherit (lib.evalModules { inherit modules; }) options;
    };
  rejects = modules: !(builtins.tryEval (check modules)).success;
  scalar = lib.mkOption { type = lib.types.str; };
  ownFile = toString ../catalog/owner/default.nix;
  otherFile = toString ../catalog/other/default.nix;
  sharedFile = toString ../catalog/_shared/languageSupport.nix;
  pinFile = toString ../catalog/_shared/pins.nix;
  declare = file: path: {
    _file = file;
    options = lib.setAttrByPath path scalar;
  };
  nested = childFile: {
    _file = ownFile;
    options.lmx.owner.example = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          _file = childFile;
          options.value = scalar;
        }
      );
    };
  };
in
assert check [
  (declare ownFile [
    "lmx"
    "owner"
    "example"
  ])
];
assert check [
  (declare ownFile [
    "lmx"
    "internal"
    "owner"
    "example"
  ])
];
assert check [
  (declare pinFile [
    "lmx"
    "pins"
  ])
];
assert check [
  (declare sharedFile [
    "lmx"
    "capabilities"
    "languageSupport"
    "example"
  ])
];
assert check [
  (declare (toString ../interface.nix) [
    "limanix"
    "example"
  ])
];
assert check [
  (declare (toString ../catalog/_shared/test/platform.nix) [
    "environment"
    "systemPackages"
  ])
];
assert check [ (nested ownFile) ];
assert check [
  (declare ownFile [
    "lmx"
    "owner"
    "example"
  ])
  {
    _file = otherFile;
    config.lmx.owner.example = "public assignment";
  }
];
assert rejects [ (nested otherFile) ];
assert rejects [
  (declare otherFile [
    "lmx"
    "owner"
    "example"
  ])
];
assert rejects [
  (declare otherFile [
    "lmx"
    "internal"
    "owner"
    "example"
  ])
];
assert rejects [
  (declare ownFile [
    "services"
    "example"
  ])
];
assert rejects [
  (declare ownFile [
    "lmx"
    "capabilities"
    "languageSupport"
    "example"
  ])
];
assert rejects [
  (declare ownFile [
    "lmx"
    "pins"
  ])
];
assert rejects [
  (declare pinFile [
    "lmx"
    "capabilities"
    "pins"
    "example"
  ])
];
assert rejects [
  (declare sharedFile [
    "lmx"
    "internal"
    "example"
  ])
];
assert rejects [
  (declare (toString ../catalog/_shared/lib/example.nix) [
    "lmx"
    "internal"
    "example"
  ])
];
assert rejects [
  (declare (toString ../catalog/_shared/test.nix) [
    "lmx"
    "capabilities"
    "test"
    "example"
  ])
];
assert rejects [
  (declare "/third-party/default.nix" [
    "limanix"
    "example"
  ])
];
assert rejects [
  (declare "/third-party/default.nix" [
    "lmx"
    "owner"
    "example"
  ])
];
assert check [
  (declare "/third-party/default.nix" [
    "services"
    "example"
  ])
];
true
