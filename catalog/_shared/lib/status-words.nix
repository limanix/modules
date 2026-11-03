# Prompt status for Bash and Zsh; tmux shows it in its status line instead.
# Source after prompt initialization so status refreshes before the prompt draws.
let
  update = ''
    _lmx_status_words() {
      local code=$?
      LMX_STATUS_WORDS=
      [ -n "''${TMUX-}" ] || LMX_STATUS_WORDS=$(/run/current-system/sw/bin/lmx status --short 2>/dev/null)
      export LMX_STATUS_WORDS
      return $code
    }
  '';
in
{
  bash = update + ''
    if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == "declare -a"* ]]; then
      PROMPT_COMMAND=(_lmx_status_words "''${PROMPT_COMMAND[@]}")
    else
      PROMPT_COMMAND="_lmx_status_words''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    fi
  '';
  zsh = update + ''
    precmd_functions=(_lmx_status_words ''${precmd_functions[@]})
  '';
}
