{ pkgs, lib }:
let
  check = modules: import ./shared-declarations.nix { inherit lib pkgs modules; };
  rejects = modules: !(builtins.tryEval (check modules)).success;
  declaration = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };
  publicFile = toString ../catalog/_shared/languageSupport.nix;
  pinsFile = toString ../catalog/_shared/pins.nix;
  module = file: {
    _file = file;
    options.lmx.capabilities.languageSupport.example = declaration;
  };
in
assert check [ (module publicFile) ];
assert check [
  {
    _file = pinsFile;
    options.lmx.pins = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  }
];
assert rejects [
  {
    _file = publicFile;
    config.environment.systemPackages = [ pkgs.hello ];
  }
];
assert rejects [
  {
    _file = publicFile;
    imports = [ { _file = toString ../catalog/_shared/test/helpers.nix; } ];
  }
];
assert rejects [
  {
    _file = publicFile;
    imports = [ { _file = "/third-party/default.nix"; } ];
  }
];
assert rejects [ { _file = toString ../catalog/_shared/test.nix; } ];
true
