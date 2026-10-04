{
  config,
  profile,
  profileFor,
  pkgs,
  version,
  tools,
  expectedTools,
  olderTools,
  allConfiguration,
  includeShared,
  configurations,
  ...
}:
let
  tool = config.lmx.capabilities.languageSupport.tools.rust-analyzer;
  older = olderTools;
  expectedProvider = older.rust-analyzer;
  overridden = configurations.userOverride;
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
  userOverride = pkgs.runCommand "rust-user-selected-provider" { } ''
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
  allLines = import ../../_shared/test/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allConfiguration;
    expectedCommands = {
      rustc = "${expectedTools.rustc}/bin/rustc";
      rustdoc = "${expectedTools.rustc}/bin/rustdoc";
      cargo = "${expectedTools.cargo}/bin/cargo";
      rustfmt = "${expectedTools.rustfmt}/bin/rustfmt";
      cargo-clippy = "${expectedTools.clippy}/bin/cargo-clippy";
      rust-analyzer = "${expectedTools.rust-analyzer}/bin/rust-analyzer";
    };
  };
}
