{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.lmx.tmux.navigation.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Ctrl/Alt-H/J/K/L pane navigation and prefix key forwarding.";
  };

  config = {
    limanix.session.command = lib.mkDefault (
      pkgs.writeShellScript "limanix-tmux-session" ''
        limanix_tmux_command=${lib.escapeShellArg "${pkgs.tmux}/bin/tmux"}
        ${builtins.readFile ./session.sh}
      ''
    );

    programs.tmux = {
      enable = true;
      keyMode = lib.mkDefault "vi";
      terminal = lib.mkDefault "tmux-256color";
      escapeTime = lib.mkDefault 10;
      plugins = with pkgs.tmuxPlugins; [
        resurrect
        continuum
      ];
      extraConfigBeforePlugins =
        builtins.readFile ./tmux.conf
        + lib.optionalString config.lmx.tmux.navigation.enable (builtins.readFile ./navigation.conf);
    };
  };
}
