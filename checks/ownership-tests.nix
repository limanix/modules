{
  nixpkgs,
  system,
}:
let
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;
  check =
    modules:
    let
      evaluated = lib.evalModules { inherit modules; };
    in
    import ./ownership.nix {
      inherit lib;
      inherit (evaluated) options;
    };
  rejects = modules: !(builtins.tryEval (check modules)).success;
  scalar = lib.mkOption { type = lib.types.str; };
  tmuxFile = toString ../catalog/tmux/default.nix;
  zshFile = toString ../catalog/zsh/default.nix;
  languageSupportFile = toString ../catalog/_shared/languageSupport.nix;
  nested = file: childFile: {
    _file = file;
    options.lmx.tmux.example = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          _file = childFile;
          options.value = scalar;
        }
      );
    };
  };
  valid = {
    _file = tmuxFile;
    options.lmx.tmux.example = scalar;
  };
in
assert check [ valid ];
assert check [
  valid
  {
    _file = zshFile;
    config.lmx.tmux.example = "A public assignment does not transfer declaration ownership.";
  }
];
assert check [ (nested tmuxFile tmuxFile) ];
assert rejects [ (nested tmuxFile zshFile) ];
assert rejects [
  {
    _file = zshFile;
    options.lmx.tmux.example = scalar;
  }
];
assert rejects [
  {
    _file = tmuxFile;
    options.services.example = scalar;
  }
];
assert rejects [
  {
    _file = languageSupportFile;
    options.lmx.editor.example = scalar;
  }
];
assert rejects [
  {
    _file = tmuxFile;
    options.lmx.capabilities.languageSupport.example = scalar;
  }
];
assert rejects [
  {
    _file = toString ../catalog/_shared/internal/example.nix;
    options.lmx.tmux.example = scalar;
  }
];
assert rejects [
  {
    _file = "/third-party/default.nix";
    options.limanix.example = scalar;
  }
];
assert rejects [
  {
    _file = "/third-party/default.nix";
    options.lmx.internal.example = scalar;
  }
];
assert rejects [
  {
    _file = "/third-party/default.nix";
    options.lmx.tmux.example = scalar;
  }
];
assert check [
  {
    _file = toString ../interface.nix;
    options.limanix.example = scalar;
  }
];
assert check [
  {
    _file = toString ../catalog/_shared/internal/example.nix;
    options.lmx.internal.example = scalar;
  }
];
true
