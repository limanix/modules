{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.capabilities) theme;
  color = role: ''\[\e[${import ../../_shared/lib/sgr.nix lib theme.colors.${role}}m\]'';
  reset = ''\[\e[0m\]'';
  colors = pkgs.writeText "bash-git-prompt-limanix.bgptheme" ''
    override_git_prompt_colors() {
      GIT_PROMPT_THEME_NAME="LimaNix"
      GIT_PROMPT_PREFIX=""
      GIT_PROMPT_SUFFIX=""
      GIT_PROMPT_SEPARATOR=" "
      GIT_PROMPT_BRANCH="${color "purple"}"
      GIT_PROMPT_STAGED="${color "green"}●"
      GIT_PROMPT_CONFLICTS="${color "red"}✖"
      GIT_PROMPT_CHANGED="${color "orange"}✚"
      GIT_PROMPT_REMOTE=" "
      GIT_PROMPT_UNTRACKED="${color "cyan"}…"
      GIT_PROMPT_STASHED="${color "cyan"}⚑"
      GIT_PROMPT_CLEAN="${color "green"}✔"
      GIT_PROMPT_COMMAND_OK="${color "green"}✔"
      GIT_PROMPT_COMMAND_FAIL="${color "red"}✘ _LAST_COMMAND_STATE_"
      GIT_PROMPT_SYMBOLS_AHEAD="${color "cyan"}↑"
      GIT_PROMPT_SYMBOLS_BEHIND="${color "cyan"}↓"
      GIT_PROMPT_SYMBOLS_NO_REMOTE_TRACKING="${color "muted"}local"
      GIT_PROMPT_START_USER="_LAST_COMMAND_INDICATOR_ ${color "blue"}\w${reset}"
      GIT_PROMPT_START_ROOT="_LAST_COMMAND_INDICATOR_ ${color "red"}\w${reset}"
      GIT_PROMPT_END_USER="${reset}\n${color "accent"}❯${reset} "
      GIT_PROMPT_END_ROOT="${reset}\n${color "red"}#${reset} "
    }
    reload_git_prompt_colors "LimaNix"
  '';
in
{
  imports = [ ./help.nix ];

  programs.bash.promptInit = lib.mkDefault ''
    if [[ $TERM != dumb ]]; then
      GIT_PROMPT_FETCH_REMOTE_STATUS=''${GIT_PROMPT_FETCH_REMOTE_STATUS-0}
      [[ -n ''${GIT_PROMPT_THEME_FILE-} || -r ~/.git-prompt-colors.sh ]] || GIT_PROMPT_THEME_FILE=${colors}
      prompt_callback() {
        [[ -n ''${TMUX-} ]] && return
        local words
        words=$(/run/current-system/sw/bin/lmx status --short 2>/dev/null)
        [[ -n $words ]] && printf ' %s%s%s' '${color "orange"}' "$words" '${reset}'
      }
      source ${pkgs.bash-git-prompt}/gitprompt.sh
    fi
  '';
}
