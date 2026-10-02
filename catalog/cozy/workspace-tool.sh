# Variables are supplied by workspace.nix.
# shellcheck disable=SC2154
set -uo pipefail

if test -x "$cozy_command"; then
  "$cozy_command" || printf 'Workspace %s exited with status %s; opening a shell.\n' "$cozy_window" "$?" >&2
else
  printf 'Workspace %s is unavailable; opening a shell.\n' "$cozy_window" >&2
fi

if ! test -x "$cozy_shell"; then
  cozy_shell=$cozy_fallback_shell
fi
exec "$cozy_shell"
