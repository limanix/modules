{
  nixpkgs,
  system,
}:
let
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;
  check = modules: import ./shared-declarations.nix { inherit lib pkgs modules; };
  rejects = modules: !(builtins.tryEval (check modules)).success;
  publicFile = toString ../catalog/_shared/languageSupport.nix;
  privateFile = toString ../catalog/_shared/internal/example.nix;
  declaration = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };
in
assert check [
  {
    _file = publicFile;
    options.lmx.capabilities.languageSupport.example = declaration;
  }
];
assert check [
  {
    _file = privateFile;
    options.lmx.internal.example = declaration;
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
    _file = privateFile;
    config.services.openssh.enable = true;
  }
];
assert rejects [
  {
    _file = publicFile;
    imports = [
      {
        _file = toString ../catalog/tmux/default.nix;
        options.lmx.tmux.example = declaration;
      }
    ];
  }
];
true
