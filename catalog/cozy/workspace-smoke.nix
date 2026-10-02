{ pkgs }:
let
  fixture =
    name: command:
    pkgs.writeShellScriptBin command ''
      printf '%s\0%s\0' ${pkgs.lib.escapeShellArg name} "$PWD" > "$LMX_WORKSPACE_STATE/$TMUX_PANE"
      exec ${
        if name == "shell" then
          "${pkgs.bashInteractive}/bin/bash --noprofile --norc"
        else
          "${pkgs.coreutils}/bin/sleep 3600"
      }
    '';
  editor = fixture "editor" "nvim";
  shell = (fixture "shell" "workspace-shell") // {
    shellPath = "/bin/workspace-shell";
  };
  git = fixture "git" "lazygit";
  containers = fixture "containers" "lazydocker";
  missing = pkgs.writeText "missing-workspace-tools" "";
  failing = pkgs.writeShellScriptBin "nvim" "exit 17";
  raceTmux = pkgs.writeShellScriptBin "tmux" ''
    if test "''${1:-}" = has-session && ! ${pkgs.tmux}/bin/tmux "$@" 2>/dev/null; then
      ${pkgs.coreutils}/bin/touch "$LMX_WORKSPACE_RACE_DIR/$BASHPID"
      attempt=0
      while true; do
        markers=("$LMX_WORKSPACE_RACE_DIR"/*)
        if (( ''${#markers[@]} >= 2 )); then
          exit 1
        fi
        ((attempt+=1))
        test "$attempt" -lt 1000 || exit 70
        ${pkgs.coreutils}/bin/sleep 0.01
      done
    fi
    exec ${pkgs.tmux}/bin/tmux "$@"
  '';
  workspace =
    tmuxPackage: editorPackage: gitPackage: containerPackage:
    builtins.head
      (import ./workspace.nix {
        inherit (pkgs) lib;
        pkgs = pkgs // {
          lazydocker = containerPackage;
        };
        config = {
          programs = {
            tmux.package = tmuxPackage;
            neovim.finalPackage = editorPackage;
            lazygit.package = gitPackage;
          };
          limanix.user.shell = shell;
        };
      }).environment.systemPackages;
  command = workspace pkgs.tmux editor git containers;
  fallback = workspace pkgs.tmux missing missing missing;
  failure = workspace pkgs.tmux failing git containers;
  race = workspace raceTmux editor git containers;
in
pkgs.runCommand "tmux-project-workspace"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    LMX_PROJECT_COMMAND = "${command}/bin/tmux-project";
    LMX_PROJECT_FALLBACK_COMMAND = "${fallback}/bin/tmux-project";
    LMX_PROJECT_FAILURE_COMMAND = "${failure}/bin/tmux-project";
    LMX_PROJECT_RACE_COMMAND = "${race}/bin/tmux-project";
    LMX_TMUX = "${pkgs.tmux}/bin/tmux";
    TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
  }
  ''
    export HOME="$TMPDIR/home"
    export TMUX_TMPDIR="$TMPDIR/tmux"
    export TERM=xterm-256color
    export LMX_WORKSPACE_STATE="$TMPDIR/state"
    mkdir -p "$HOME" "$TMUX_TMPDIR" "$LMX_WORKSPACE_STATE"
    python ${./workspace-smoke.py}
    touch "$out"
  ''
