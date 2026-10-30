{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.capabilities) theme;
  spaceship = "${pkgs.spaceship-prompt}/lib/spaceship-prompt";
  color = role: if theme.colors.${role} == null then "default" else toString theme.colors.${role};
  # Spaceship's sections name their default colors; each becomes the color of a role.
  roles = {
    cyan = "cyan";
    magenta = "purple";
    red = "red";
    green = "green";
    yellow = "yellow";
    blue = "blue";
    white = "foreground";
    gray = "muted";
    "039" = "cyan";
    "069" = "blue";
    "105" = "purple";
    "128" = "purple";
    "133" = "purple";
    "208" = "orange";
    "26" = "blue";
    "#fbf0df" = "foreground";
    "#ff8cff" = "pink";
  };
  settings =
    pkgs.runCommandLocal "spaceship-limanix.zsh"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        colors = builtins.toJSON (lib.mapAttrs (_: color) roles);
        symbols = builtins.toJSON {
          SPACESHIP_GIT_SYMBOL = "";
          SPACESHIP_DIR_LOCK_SYMBOL = " ro";
          SPACESHIP_PULUMI_SYMBOL = "pulumi ";
        };
        extra = ''
          SPACESHIP_RPROMPT_ORDER=(lmx)
          spaceship_lmx() {
            [[ -n $TMUX ]] && return
            local words=$(/run/current-system/sw/bin/lmx status --short 2>/dev/null)
            [[ -n $words ]] && spaceship::section --color '${color "orange"}' "''${words//\%/%%}"
          }
        '';
      }
      ''
        python3 ${./settings.py} ${spaceship} "$out"
      '';
in
{
  imports = [ ./help.nix ];

  programs.zsh.promptInit = lib.mkDefault ''
    if [[ $TERM != dumb ]]; then
      [[ $COLORTERM == (truecolor|24bit) ]] || zmodload zsh/nearcolor
      source ${settings}
      source ${spaceship}/spaceship.zsh
    fi
  '';
}
