{
  config,
  profile,
  profileFor,
  pkgs,
  version,
  allVersionsConfiguration,
  includeShared,
  configurations,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  tool = config.lmx.capabilities.languageSupport.tools.rust-analyzer;
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  lines = builtins.sort pkgs.lib.versionOlder metadata.versions;
  older = import ./packages.nix {
    version = builtins.head lines;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  expectedProvider = configurations.providerOverrideExpectedPackage or older.rust-analyzer;
  overridden = configurations.providerOverride;
  overriddenProfile = profileFor overridden;
  selected = overridden.config.lmx.capabilities.languageSupport.tools.rust-analyzer;
in
{
  commands =
    pkgs.runCommand "rust-${version}-commands-smoke"
      {
        nativeBuildInputs = [ profile ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        test "$(readlink -f ${profile}/bin/rustc-${version})" = "$(readlink -f ${tools.rustc}/bin/rustc)"
        test "$(readlink -f ${profile}/bin/rust-analyzer)" = "$(readlink -f ${tool.command})"
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
// pkgs.lib.optionalAttrs includeShared {
  providerOverride = pkgs.runCommand "rust-user-selected-provider" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${overriddenProfile}/bin/rust-analyzer)" = \
      "$(readlink -f ${expectedProvider}/bin/rust-analyzer)"
    test "$(readlink -f ${selected.command})" = \
      "$(readlink -f ${overriddenProfile}/bin/rust-analyzer)"
    test "$(${overriddenProfile}/bin/rust-analyzer --version)" = \
      "$(${selected.command} ${pkgs.lib.escapeShellArgs selected.args})"
    touch "$out"
  '';
  coexistence = import ../../checks/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
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
}
