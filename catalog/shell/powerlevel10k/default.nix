{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.capabilities) theme;
  p10k = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
  color = role: if theme.colors.${role} == null then "default" else toString theme.colors.${role};
  # The eight-color lean style names terminal colors by number; each becomes the color of a role.
  roles = {
    "1" = "red";
    "2" = "green";
    "3" = "yellow";
    "4" = "blue";
    "5" = "purple";
    "6" = "cyan";
    "7" = "subtle";
    "67" = "blue";
    "208" = "orange";
  };
  style =
    pkgs.runCommandLocal "powerlevel10k-limanix.zsh"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        colors = builtins.toJSON (lib.mapAttrs (_: color) roles);
        extra = ''
          typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
          typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(lmx $POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS)
          function prompt_lmx() {
            [[ -n $TMUX ]] && return
            local words=$(/run/current-system/sw/bin/lmx status --short 2>/dev/null)
            [[ -n $words ]] && p10k segment -f '${color "orange"}' -t "%B''${words//\%/%%}%b"
          }
        '';
      }
      ''
        python3 ${./style.py} ${p10k}/config/p10k-lean-8colors.zsh "$out"
      '';
in
{
  imports = [ ./help.nix ];

  programs.zsh.promptInit = lib.mkDefault ''
    if [[ $TERM != dumb ]]; then
      [[ $COLORTERM == (truecolor|24bit) ]] || zmodload zsh/nearcolor
      source ${p10k}/powerlevel10k.zsh-theme
      source ${style}
    fi
  '';
}
