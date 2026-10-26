{
  evalSystem,
  pkgs,
  lib,
}:
import ../../_shared/test/toolchain.nix {
  inherit evalSystem pkgs lib;
  spec = import ./toolchain.nix;
  coexisting = [
    "go"
    "gopls"
    "delve"
  ];
  check = { installed, ... }: installed pkgs.gcc;
  profileCommands = tools: {
    go = "${tools.go}/bin/go";
    gopls = "${tools.gopls}/bin/gopls";
    dlv = "${tools.delve}/bin/dlv";
  };
  commands =
    {
      line,
      profile,
      tools,
      provider,
      ...
    }:
    pkgs.runCommand "go-${line}-commands-smoke" { nativeBuildInputs = [ profile ]; } ''
      export HOME="$TMPDIR/home" GOTOOLCHAIN=local CGO_ENABLED=1
      mkdir -p "$HOME"
      test "$(readlink -f ${profile}/bin/go-${line})" = "$(readlink -f ${tools.go}/bin/go)"
      go-${line} version | grep -F 'go${tools.go.version}'
      test "$(readlink -f ${profile}/bin/gopls)" = "$(readlink -f ${provider.command})"
      gopls version
      dlv version
      mkdir project
      cd project
      printf 'module example\n\ngo 1.24\n' > go.mod
      printf 'package example\nimport "C"\nfunc Answer() int { return 42 }\n' > example.go
      printf 'package example\nimport "testing"\nfunc TestAnswer(t *testing.T) { if Answer() != 42 { t.Fatal("answer") } }\n' > example_test.go
      go-${line} test -race ./...
      touch "$out"
    '';
}
