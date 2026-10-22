# Variables are supplied by default.nix.
# shellcheck disable=SC2154
set -euo pipefail

# An explicit configuration directory retains Yazi's native resolution.
if [[ ${YAZI_CONFIG_HOME+x} ]]; then
  exec "$limanix_yazi_command" "$@"
fi
case ${XDG_CONFIG_HOME:-} in
  /*) configuration=$XDG_CONFIG_HOME/yazi ;;
  *) configuration=$HOME/.config/yazi ;;
esac

if [[ -e "$configuration/theme.toml" || -L "$configuration/theme.toml" ]]; then
  exec "$limanix_yazi_command" "$@"
fi
if [[ ! -d "$configuration" ]]; then
  export YAZI_CONFIG_HOME=$limanix_yazi_configuration
  exec "$limanix_yazi_command" "$@"
fi

# Keep all personal settings and plugins without changing their files.
overlay=$("$limanix_yazi_mktemp" -d "${TMPDIR:-/tmp}/limanix-yazi.XXXXXXXX")
child=
# shellcheck disable=SC2329 # Invoked by the EXIT trap.
cleanup() {
  local status=$?
  trap - EXIT
  if [[ -n $child ]] && kill -0 "$child" 2>/dev/null; then
    kill -TERM "$child" 2>/dev/null || true
    wait "$child" 2>/dev/null || true
  fi
  "$limanix_yazi_rm" -rf -- "$overlay"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
shopt -s dotglob nullglob
for entry in "$configuration"/*; do
  "$limanix_yazi_ln" -s -- "$entry" "$overlay/${entry##*/}"
done
"$limanix_yazi_ln" -s -- "$limanix_yazi_theme" "$overlay/theme.toml"
export YAZI_CONFIG_HOME=$overlay
"$limanix_yazi_command" "$@" <&0 &
child=$!
status=0
wait "$child" || status=$?
child=
exit "$status"
