{
  config,
  pkgs,
  version,
  evaluate,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  tool = config.lmx.capabilities.editor.tools.rust-analyzer;
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  lines = builtins.sort pkgs.lib.versionOlder metadata.versions;
  older = import ./packages.nix {
    version = builtins.head lines;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  overridden = evaluate [
    (./versions + "/${pkgs.lib.last lines}.nix")
    {
      lmx.capabilities.editor.tools.rust-analyzer = {
        package = older.rust-analyzer;
        command = "${older.rust-analyzer}/bin/rust-analyzer";
        args = [ "--version" ];
        languages = [ "rust" ];
      };
    }
  ];
  selected = overridden.config.lmx.capabilities.editor.tools.rust-analyzer;
in
{
  providerOverride = pkgs.runCommand "rust-user-selected-provider" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${overridden.config.system.path}/bin/rust-analyzer)" = \
      "$(readlink -f ${older.rust-analyzer}/bin/rust-analyzer)"
    test "$(readlink -f ${selected.command})" = \
      "$(readlink -f ${overridden.config.system.path}/bin/rust-analyzer)"
    test "$(${overridden.config.system.path}/bin/rust-analyzer --version)" = \
      "$(${selected.command} ${pkgs.lib.escapeShellArgs selected.args})"
    touch "$out"
  '';
  coexistence = import ../../checks/profile-commands.nix {
    inherit pkgs evaluate;
    directory = ./.;
    commands = {
      rustc = "rustc";
      rustdoc = "rustc";
      cargo = "cargo";
      rustfmt = "rustfmt";
      cargo-clippy = "clippy";
      rust-analyzer = "rust-analyzer";
    };
  };
  commands =
    pkgs.runCommand "rust-${version}-commands-smoke"
      {
        nativeBuildInputs = [ config.system.path ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        test "$(readlink -f ${config.system.path}/bin/rustc-${version})" = "$(readlink -f ${tools.rustc}/bin/rustc)"
        test "$(readlink -f ${config.system.path}/bin/rust-analyzer)" = "$(readlink -f ${tool.command})"
        rustc-${version} --version | grep -F '${tools.rustc.version}'
        rustdoc-${version} --version
        rustfmt-${version} --version
        rust-analyzer-${version} --version
        cargo-${version} new --vcs none example
        cd example
        cargo-${version} build --offline
        cargo-${version} test --offline
        cargo-${version} fmt -- --check
        cargo-${version} clippy --offline -- -D warnings
        touch "$out"
      '';
}
