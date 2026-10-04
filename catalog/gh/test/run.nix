{ pkgs, profile }:
{
  commands =
    pkgs.runCommand "gh-system-commands"
      {
        nativeBuildInputs = [ profile ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        export GH_CONFIG_DIR="$HOME/.config/gh" GH_PROMPT_DISABLED=1
        gh --version
        gh help pr > help.txt
        grep -F 'pull requests' help.txt
        touch "$out"
      '';
}
