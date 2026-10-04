{
  pkgs,
  profile,
  shell,
}:
{
  commands =
    pkgs.runCommand "cozy-system-commands"
      {
        nativeBuildInputs = [ profile ];
      }
      ''
        export HOME="$TMPDIR/home" TERM=xterm-256color
        export AWS_EC2_METADATA_DISABLED=true CLOUDSDK_CONFIG="$HOME/.config/gcloud"
        export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK=true
        mkdir -p "$HOME"
        tmux -V
        nvim --version
        git --version
        lazydocker --version
        docker --version
        docker compose version
        minikube version
        k9s version
        go version
        gopls version
        node -e 'if (!process.version.startsWith("v")) process.exit(1)'
        npm --version
        python3 -c 'import venv; print("python runtime available")'
        aws --version
        gcloud version
        posting locate config
        harlequin --version
        set +e
        tmux-project one two > invalid-arguments.txt 2>&1
        status=$?
        set -e
        test "$status" = 64
        set +e
        tmux-project "$TMPDIR/missing-project" > missing-project.txt 2>&1
        status=$?
        set -e
        test "$status" = 1
        touch "$out"
      '';
  workspace =
    pkgs.runCommand "cozy-system-workspace"
      {
        nativeBuildInputs = [
          profile
          pkgs.python3
        ];
        LMX_PROJECT_COMMAND = "${profile}/bin/tmux-project";
        LMX_TMUX = "${profile}/bin/tmux";
        LMX_SHELL = shell;
        PYTHONPATH = ../../_shared/test;
        TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
      }
      ''
        export HOME="$TMPDIR/home" TERM=xterm-256color COLORTERM=truecolor
        export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
        export XDG_CACHE_HOME="$HOME/.cache" ZDOTDIR="$HOME"
        export TMUX_TMPDIR="$TMPDIR/tmux" DOCKER_HOST="unix://$TMPDIR/unavailable-docker.sock"
        export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
        unset TMUX TMUX_PANE
        mkdir -p "$HOME" "$TMUX_TMPDIR" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
        # Native checks use temporary user state, without NixOS activation.
        printf 'PROMPT="workspace> "\n' > "$HOME/.zshrc"
        python ${./workspace.py}
        touch "$out"
      '';
}
