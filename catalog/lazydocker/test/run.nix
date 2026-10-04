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
        lazydocker --version
        lazydocker --help > help.txt
        test -s help.txt
        touch "$out"
      '';
}
