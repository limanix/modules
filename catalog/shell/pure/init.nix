# Initialization of the Pure prompt in the colors of the guest's theme: the terminal's own colors
# with the system theme, the theme's palette otherwise. Outside tmux, the right prompt shows the
# words of `lmx status --short`; inside tmux, its status line shows them.
{
  lib,
  pure,
  theme,
}:
let
  # A role as a zsh color: the terminal's color number, or the palette's #rrggbb.
  color = role: if theme.colors.${role} == null then "default" else toString theme.colors.${role};
  colors = lib.mapAttrs (_: color) {
    path = "blue";
    "git:branch" = "purple";
    "git:branch:cached" = "red";
    "git:dirty" = "orange";
    "git:arrow" = "cyan";
    "git:stash" = "cyan";
    "git:action" = "yellow";
    host = "accent";
    user = "accent";
    "user:root" = "red";
    execution_time = "yellow";
    virtualenv = "muted";
    "prompt:success" = "green";
    "prompt:error" = "red";
    "prompt:continuation" = "muted";
  };
in
''
  if [[ $TERM != dumb ]]; then
    # Hex colors need a truecolor terminal; elsewhere the nearest of 256 colors replaces them.
    [[ $COLORTERM == (truecolor|24bit) ]] || zmodload zsh/nearcolor
    fpath+=(${pure}/share/zsh/site-functions)
    autoload -Uz promptinit && promptinit
  ${
    lib.concatStrings (
      lib.mapAttrsToList (name: color: "  zstyle ':prompt:pure:${name}' color '${color}'\n") colors
    )
  }  prompt pure

    # The hook refreshes the words only; a personal RPROMPT in ~/.zshrc replaces the segment.
    typeset -g _lmx_prompt_words=
    _lmx_prompt_status() {
      local words
      [[ -n $TMUX ]] || words=$(/run/current-system/sw/bin/lmx status --short 2>/dev/null)
      _lmx_prompt_words=''${words:+"%B%F{${color "orange"}}''${words//\%/%%}%f%b"}
    }
    autoload -Uz add-zsh-hook && add-zsh-hook precmd _lmx_prompt_status
    setopt prompt_subst
    RPROMPT='$_lmx_prompt_words'
  fi
''
