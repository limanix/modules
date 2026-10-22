{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.capabilities) theme;
  names = builtins.attrNames theme.palette;
  # tmux's names of the terminal's 16 colors, which it also prints back.
  terminal = [
    "black"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "white"
    "brightblack"
    "brightred"
    "brightgreen"
    "brightyellow"
    "brightblue"
    "brightmagenta"
    "brightcyan"
    "brightwhite"
  ];
  # A palette name as a tmux color: the terminal's own with the system flavor, the flavor's otherwise.
  color =
    name:
    if theme.flavor != "system" then
      theme.palette.${name}
    else if theme.ansi.${name} == null then
      "default"
    else
      builtins.elemAt terminal theme.ansi.${name};
  styles = lib.replaceStrings (map (name: "@theme-${name}@") names) (map color names) (
    builtins.readFile ./tmux.conf
  );
in
{
  imports = [ ./help.nix ];

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
        styles + lib.optionalString config.lmx.tmux.navigation.enable (builtins.readFile ./navigation.conf);
    };
  };
}
