{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.capabilities) theme;
  words = import ../../_shared/lib/status-words.nix;
  settings = pkgs.writeText "oh-my-posh-limanix.json" (
    builtins.toJSON {
      "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
      version = 3;
      final_space = true;
      palette = lib.mapAttrs (_: toString) (lib.filterAttrs (_: color: color != null) theme.colors);
      blocks = [
        {
          type = "prompt";
          alignment = "left";
          segments = [
            {
              type = "session";
              style = "plain";
              foreground = "p:accent";
              template = "{{ .UserName }}@{{ .HostName }} ";
            }
            {
              type = "path";
              style = "plain";
              foreground = "p:blue";
              template = "{{ .Path }} ";
              options.style = "full";
            }
            {
              type = "git";
              style = "plain";
              foreground = "p:purple";
              template = "{{ .HEAD }}{{ if .Working.Changed }}<p:orange>*</>{{ end }}{{ if gt .Ahead 0 }}<p:cyan> ↑{{ .Ahead }}</>{{ end }}{{ if gt .Behind 0 }}<p:cyan> ↓{{ .Behind }}</>{{ end }} ";
              options = {
                fetch_status = true;
                branch_icon = "";
                commit_icon = "@";
                tag_icon = "#";
              };
            }
            {
              type = "executiontime";
              style = "plain";
              foreground = "p:yellow";
              template = "{{ .FormattedMs }} ";
              options = {
                threshold = 5000;
                style = "round";
              };
            }
            {
              type = "text";
              style = "plain";
              foreground = "p:orange";
              template = "{{ if .Env.LMX_STATUS_WORDS }}<b>{{ .Env.LMX_STATUS_WORDS }}</b>{{ end }}";
            }
          ];
        }
        {
          type = "prompt";
          alignment = "left";
          newline = true;
          segments = [
            {
              type = "status";
              style = "plain";
              foreground = "p:green";
              foreground_templates = [ "{{ if gt .Code 0 }}p:red{{ end }}" ];
              template = "❯";
              options.always_enabled = true;
            }
          ];
        }
      ];
    }
  );
  init = shell: ''
    if [[ $TERM != dumb ]]; then
      eval "$(${pkgs.oh-my-posh}/bin/oh-my-posh init ${shell} --config "''${POSH_THEME:-${settings}}")"
    ${words.${shell}}
    fi
  '';
in
{
  imports = [ ./help.nix ];

  environment.systemPackages = [ pkgs.oh-my-posh ];

  programs.bash.promptInit = lib.mkDefault (init "bash");
  programs.zsh.promptInit = lib.mkDefault (init "zsh");
}
