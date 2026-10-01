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
  tool = config.lmx.capabilities.languageSupport.tools.gopls;
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  lines = builtins.sort pkgs.lib.versionOlder metadata.versions;
  older = import ./packages.nix {
    version = builtins.head lines;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  overridden = configurations.providerOverride;
  overriddenProfile = profileFor overridden;
  selected = overridden.config.lmx.capabilities.languageSupport.tools.gopls;
in
{
  commands =
    pkgs.runCommand "go-${version}-commands-smoke"
      {
        nativeBuildInputs = [ profile ];
      }
      ''
        export HOME="$TMPDIR/home" GOTOOLCHAIN=local CGO_ENABLED=1
        mkdir -p "$HOME"
        test "$(readlink -f ${profile}/bin/go-${version})" = "$(readlink -f ${tools.go}/bin/go)"
        go-${version} version | grep -F 'go${tools.go.version}'
        test "$(readlink -f ${profile}/bin/gopls)" = "$(readlink -f ${tool.command})"
        gopls version
        dlv version
        mkdir project
        cd project
        printf 'module example\n\ngo 1.24\n' > go.mod
        printf 'package example\nimport "C"\nfunc Answer() int { return 42 }\n' > example.go
        printf 'package example\nimport "testing"\nfunc TestAnswer(t *testing.T) { if Answer() != 42 { t.Fatal("answer") } }\n' > example_test.go
        go-${version} test -race ./...
        touch "$out"
      '';
}
// pkgs.lib.optionalAttrs includeShared {
  providerOverride = pkgs.runCommand "go-user-selected-provider" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${overriddenProfile}/bin/gopls)" = \
      "$(readlink -f ${older.gopls}/bin/gopls)"
    test "$(readlink -f ${selected.command})" = \
      "$(readlink -f ${overriddenProfile}/bin/gopls)"
    test "$(${overriddenProfile}/bin/gopls version)" = \
      "$(${selected.command} ${pkgs.lib.escapeShellArgs selected.args})"
    touch "$out"
  '';
  coexistence = import ../../checks/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    directory = ./.;
    commands = {
      go = "go";
      gopls = "gopls";
      dlv = "delve";
    };
  };
}
