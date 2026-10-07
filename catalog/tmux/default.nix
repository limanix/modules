{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.capabilities.theme) palette;
  colors = builtins.attrNames palette;
  theme = lib.replaceStrings (map (name: "@theme-${name}@") colors) (map (
    name: palette.${name}
  ) colors) (builtins.readFile ./tmux.conf);
in
{
  options.lmx.tmux.navigation.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Ctrl/Alt-H/J/K/L pane navigation and prefix key forwarding.";
  };

  config = {
    limanix.session.command = lib.mkDefault (
      pkgs.writeShellScript "limanix-tmux-session" ''
        limanix_tmux_command=${lib.escapeShellArg "${config.programs.tmux.package}/bin/tmux"}
        ${builtins.readFile ./session.sh}
      ''
    );

    programs.tmux = {
      enable = true;
      keyMode = lib.mkDefault "vi";
      terminal = lib.mkDefault "tmux-256color";
      escapeTime = lib.mkDefault 10;
      plugins = import ./plugins.nix { inherit pkgs; };
      extraConfigBeforePlugins =
        theme + lib.optionalString config.lmx.tmux.navigation.enable (builtins.readFile ./navigation.conf);
    };
  };
}
