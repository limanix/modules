{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.capabilities) theme;
  sgr = role: import ../../_shared/lib/sgr.nix lib theme.palette.${role};
  background = role: "48" + lib.removePrefix "38" (sgr role);
  # Liquidprompt names terminal colors; each becomes the color of a role.
  colors = {
    RED = sgr "red";
    BOLD_RED = "1;${sgr "red"}";
    GREEN = sgr "green";
    BOLD_GREEN = "1;${sgr "green"}";
    YELLOW = sgr "yellow";
    BOLD_YELLOW = "1;${sgr "yellow"}";
    BLUE = sgr "blue";
    BOLD_BLUE = "1;${sgr "blue"}";
    PURPLE = sgr "purple";
    MAGENTA = sgr "purple";
    PINK = "1;${sgr "pink"}";
    BOLD_PURPLE = "1;${sgr "purple"}";
    BOLD_MAGENTA = "1;${sgr "purple"}";
    CYAN = sgr "cyan";
    BOLD_CYAN = "1;${sgr "cyan"}";
    WHITE = sgr "subtle";
    BOLD_WHITE = "1;${sgr "foreground"}";
    BLACK = sgr "background_darker";
    BOLD_GRAY = "1;${sgr "muted"}";
    WARN_RED = "${sgr "background_darker"};${background "red"}";
    CRIT_RED = "1;${sgr "foreground"};${background "red"}";
    DANGER_RED = "1;${sgr "yellow"};${background "red"}";
    LMX_MUTED = sgr "muted";
  };
  settings =
    pkgs.runCommandLocal "liquidpromptrc"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        colors = builtins.toJSON colors;
      }
      ''
        python3 ${./settings.py} ${pkgs.liquidprompt}/bin/liquidprompt "$out"
      '';
  wrap = {
    bash = sequence: ''\[''${esc}${sequence}\]'';
    zsh = sequence: "%{\${esc}${sequence}%}";
  };
  hook = {
    bash = ''
      if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == "declare -a"* ]]; then
        PROMPT_COMMAND=(_lmx_liquidprompt_words "''${PROMPT_COMMAND[@]}")
      else
        PROMPT_COMMAND="_lmx_liquidprompt_words''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
      fi
    '';
    zsh = ''
      precmd_functions=(_lmx_liquidprompt_words ''${precmd_functions[@]})
    '';
  };
  init = shell: ''
    if [[ $TERM != dumb && $- == *i* ]]; then
      source ${pkgs.liquidprompt}/bin/liquidprompt
      _lmx_mark_prefix=$LP_MARK_PREFIX
      _lmx_liquidprompt_words() {
        local code=$? words= esc=$'\e'
        [ -n "''${TMUX-}" ] || words=$(/run/current-system/sw/bin/lmx status --short 2>/dev/null)
        LP_MARK_PREFIX=''${words:+" ${
          wrap.${shell} "[1;${import ../../_shared/lib/sgr.nix lib theme.colors.orange}m"
        }$words${wrap.${shell} "[0m"}"}$_lmx_mark_prefix
        return $code
      }
    ${hook.${shell}}
    fi
  '';
in
{
  imports = [ ./help.nix ];

  environment.etc.liquidpromptrc = lib.mkIf (theme.name != "system") { source = settings; };

  programs.bash.promptInit = lib.mkDefault (init "bash");
  programs.zsh.promptInit = lib.mkDefault (init "zsh");
}
