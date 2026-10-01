name=$1
# tmux interprets -s as a format and a trailing semicolon as a command separator.
# Its literal format preserves the name without executing either syntax.
if [[ "$name" == *"#"* || "$name" == *";" ]]; then
  name=${name//#/##}
  name=${name//\}/#\}}
  name="#{l:$name}"
fi
exec "$limanix_tmux_command" new-session -A -s "$name"
