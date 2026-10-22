{
  config,
  pkgs,
  profile,
}:
{
  commands =
    pkgs.runCommand "cli-tools-system-commands"
      {
        nativeBuildInputs = [ profile ];
      }
      ''
        export HOME="$TMPDIR/home" NO_COLOR=1
        mkdir -p "$HOME"
        rg --version
        fd --version
        fzf --version
        bat --version
        eza --version
        delta --version
        jq --version
        yq --version
        xh --version
        btop --version
        dust --version
        duf --version
        tldr --version
        git --version
        printf 'module contract\n' > fixture.txt
        rg --fixed-strings 'module contract' fixture.txt
        fd --type f fixture.txt | grep -F fixture.txt
        printf 'first\nselected\n' | fzf --filter selected | grep -Fx selected
        bat --style plain --color never fixture.txt | grep -F 'module contract'
        printf '{"ready":true}\n' | jq -e .ready
        printf 'ready: true\n' | yq -e .ready
        xh --offline --print=HB GET https://example.invalid > request.txt
        grep -F 'GET / HTTP/1.1' request.txt
        touch "$out"
      '';
  gitConfig =
    pkgs.runCommand "cli-tools-git-config"
      {
        nativeBuildInputs = [ profile ];
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
        printf '[core]\n pager = cat\n' > "$HOME/.gitconfig"
        test "$(git config --get core.pager)" = cat
        touch "$out"
      '';
}
