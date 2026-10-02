# The command is supplied by default.nix.
# shellcheck disable=SC2154
if (($# != 1)) || test -z "$1"; then
  printf 'Usage: limanix-tmux-session NAME\n' >&2
  exit 64
fi
name=$1
if [[ "$name" == *.* || "$name" == *:* ]]; then
  printf "Limanix tmux session names cannot contain '.' or ':'.\n" >&2
  exit 64
fi
# tmux interprets -s as a format and a trailing semicolon as a command separator.
# Its literal format preserves the name without executing either syntax.
if [[ "$name" == *"#"* || "$name" == *";" ]]; then
  name=${name//#/##}
  name=${name//\}/#\}}
  name="#{l:$name}"
fi
exec "$limanix_tmux_command" new-session -A -s "$name"
