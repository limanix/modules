{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.capabilities.theme) colors;
  roles = builtins.attrNames colors;
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
  # A role as a tmux color: the terminal's own with the system theme, the palette's otherwise.
  color =
    role:
    let
      value = colors.${role};
    in
    if builtins.isString value then
      value
    else if value == null then
      "default"
    else
      builtins.elemAt terminal value;
  styles = lib.replaceStrings (map (role: "@theme-${role}@") roles) (map color roles) (
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
