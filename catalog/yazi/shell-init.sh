function y() {
  local lmx_yazi_tmp lmx_yazi_cwd lmx_yazi_status
  lmx_yazi_tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
  if command yazi "$@" --cwd-file="$lmx_yazi_tmp"; then
    lmx_yazi_status=0
    IFS= read -r -d '' lmx_yazi_cwd < "$lmx_yazi_tmp" || builtin true
    [ "$lmx_yazi_cwd" != "$PWD" ] && [ -d "$lmx_yazi_cwd" ] && builtin cd -- "$lmx_yazi_cwd" || builtin true
  else
    lmx_yazi_status=$?
  fi
  command rm -f -- "$lmx_yazi_tmp" || return
  return "$lmx_yazi_status"
}
