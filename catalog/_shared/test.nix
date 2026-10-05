# Reserved shared infrastructure test entry; never a root NixOS schema.
{
  evalSystem,
  pkgs,
  lib,
}:
let
  language = import ./test/language-support-tests.nix { inherit pkgs lib; };
  pins = import ./test/pins-tests.nix { inherit evalSystem lib; };
  platform = import ./test/platform-tests.nix { inherit evalSystem pkgs lib; };
  lines = import ./test/lines-tests.nix { inherit pkgs lib; };
  unitTests =
    name: directory: extra:
    pkgs.runCommand "shared-${name}-tests"
      (
        {
          PYTHONPATH = ./test;
          PYTHONDONTWRITEBYTECODE = "1";
        }
        // extra
      )
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        ${pkgs.python3.interpreter} -m unittest discover -s ${directory} -v
        touch "$out"
      '';
in
{
  eval = language.eval // pins.eval // platform.eval // lines;
  fails = language.fails // pins.fails;
  run = platform.run // {
    terminal = unitTests "terminal" ./test/terminal-tests { };
    protocol = unitTests "protocol" ./test/protocol-tests { LSP_SMOKE_SOURCE = ./test/lsp-smoke.py; };
  };
}
