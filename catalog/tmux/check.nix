{
  config,
  pkgs,
  hasPackage,
  ...
}:
config.programs.tmux.enable
&& config.limanix.session.command != null
&& config.lmx.tmux.navigation.enable
&& config.programs.tmux.keyMode == "vi"
&& config.programs.tmux.terminal == "tmux-256color"
&& config.programs.tmux.escapeTime == 10
&& builtins.all hasPackage ([ pkgs.tmux ] ++ (import ./plugins.nix { inherit pkgs; }))
