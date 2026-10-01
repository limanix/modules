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
  profile = config.system.path;
  tool = config.lmx.capabilities.editor.tools.gopls;
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  lines = builtins.sort pkgs.lib.versionOlder metadata.versions;
  older = import ./packages.nix {
    version = builtins.head lines;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  overridden = evaluate [
    (./versions + "/${pkgs.lib.last lines}.nix")
    {
      lmx.capabilities.editor.tools.gopls = {
        package = older.gopls;
        command = "${older.gopls}/bin/gopls";
        args = [ "version" ];
        languages = [ "go" ];
      };
    }
  ];
  selected = overridden.config.lmx.capabilities.editor.tools.gopls;
in
{
  providerOverride = pkgs.runCommand "go-user-selected-provider" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${overridden.config.system.path}/bin/gopls)" = \
      "$(readlink -f ${older.gopls}/bin/gopls)"
    test "$(readlink -f ${selected.command})" = \
      "$(readlink -f ${overridden.config.system.path}/bin/gopls)"
    test "$(${overridden.config.system.path}/bin/gopls version)" = \
      "$(${selected.command} ${pkgs.lib.escapeShellArgs selected.args})"
    touch "$out"
  '';
  coexistence = import ../../checks/profile-commands.nix {
    inherit pkgs evaluate;
    directory = ./.;
    commands = {
      go = "go";
      gopls = "gopls";
      dlv = "delve";
    };
  };
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
