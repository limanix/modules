{ pkgs, profile }:
{
  commands =
    pkgs.runCommand "lazydocker-system-commands"
      {
        nativeBuildInputs = [ profile ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        lazydocker --version > version.txt 2>&1
        grep -Fx 'Version: ${pkgs.lazydocker.version}' version.txt
        lazydocker --help > help.txt 2>&1
        grep -F 'lazydocker - ' help.txt
        grep -F -- '--help' help.txt
        touch "$out"
      '';
}
