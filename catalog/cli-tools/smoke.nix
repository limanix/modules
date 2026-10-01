{ config, pkgs, ... }:
{
  gitConfig =
    pkgs.runCommand "cli-tools-git-config"
      {
        nativeBuildInputs = [
          config.programs.git.package
          pkgs.delta
        ];
      }
      ''
        export GIT_CONFIG_SYSTEM=${config.environment.etc."gitconfig".source}
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        test "$(git config --get core.pager)" = '${pkgs.delta}/bin/delta'
        test "$(git config --get interactive.diffFilter)" = '${pkgs.delta}/bin/delta --color-only'
        printf 'diff --git a/file b/file\n--- a/file\n+++ b/file\n@@ -1 +1 @@\n-before\n+after\n' |
          delta --color-only > diff.txt
        test -s diff.txt
        git config --global core.pager cat
        test "$(git config --get core.pager)" = cat
        touch "$out"
      '';
}
