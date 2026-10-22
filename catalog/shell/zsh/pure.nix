# Initialization of the Pure prompt in the colors of the guest's theme: the terminal's own colors
# with the system flavor, the flavor's palette otherwise. Outside tmux, the right prompt shows the
# words of `lmx status --short`; inside tmux, its status line shows them.
{
  lib,
  pure,
  theme,
}:
let
  system = theme.flavor == "system";
  # A palette name as a zsh color: the terminal's color number, or the flavor's #rrggbb.
  color =
    name:
    if !system then
      theme.palette.${name}
    else if theme.ansi.${name} == null then
      "default"
    else
      toString theme.ansi.${name};
  colors = lib.mapAttrs (_: color) {
    path = "blue";
    "git:branch" = "mauve";
    "git:branch:cached" = "red";
    "git:dirty" = "peach";
    "git:arrow" = "teal";
    "git:stash" = "teal";
    "git:action" = "yellow";
    host = "lavender";
    user = "lavender";
    "user:root" = "red";
    execution_time = "yellow";
    virtualenv = "overlay1";
    "prompt:success" = "green";
    "prompt:error" = "red";
    "prompt:continuation" = "overlay1";
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
      _lmx_prompt_words=''${words:+"%B%F{${color "peach"}}''${words//\%/%%}%f%b"}
    }
    autoload -Uz add-zsh-hook && add-zsh-hook precmd _lmx_prompt_status
    setopt prompt_subst
    RPROMPT='$_lmx_prompt_words'
  fi
''
