{
  config,
  pkgs,
  lib,
}:
let
  check = import ./startup-check.nix { inherit config pkgs; };
  probe = pkgs.writeShellScript "zsh-activation-probe" ''
    set -eu
    test "$HOME" = /home/tester
    test "$(getent passwd tester | cut -d: -f7)" = '${pkgs.zsh}/bin/zsh'
    for file in zshenv zshrc zprofile zinputrc atuin/config.toml; do
      test -r "/etc/$file"
    done
    export TMPDIR="$(mktemp -d)" TERM=xterm-256color
    export PYTHONPATH='${../../_shared/test}'
    export LMX_ACTIVATED=1 LMX_ZSH='${pkgs.zsh}/bin/zsh' LMX_CHECK='${check}'
    trap 'rm -rf "$TMPDIR"' EXIT
    ${pkgs.python3}/bin/python ${./startup-smoke.py}
  '';
in
pkgs.testers.runNixOSTest {
  name = "zsh-activation";
  nodes.machine = {
    imports = [
      (import ../../_shared/test/vm.nix { userName = "tester"; })
      ../default.nix
    ];
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.succeed(${builtins.toJSON "su - tester -c ${lib.escapeShellArg (toString probe)}"})
  '';
}
