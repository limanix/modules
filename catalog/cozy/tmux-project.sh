# Variables are supplied by workspace.nix.
# shellcheck disable=SC2154
set -euo pipefail

if (($# > 1)); then
  printf 'Usage: tmux-project [directory]\n' >&2
  exit 64
fi

# The suffix preserves directory names ending in a newline in command substitution.
directory=$(cd -P -- "${1:-.}" && printf '%s.' "$PWD")
directory=${directory%.}
identity=$(printf '%s' "$directory" | "$cozy_sha256")
project_name=${directory##*/}
project_name=${project_name//[^a-zA-Z0-9_-]/-}
project_name=${project_name:0:24}
session="project-${project_name:-root}-${identity:0:16}"

# tmux expands -c as a format; pass the physical directory as literal text.
literal_directory=${directory//#/##}
literal_directory=${literal_directory//\}/#\}}
literal_directory="#{l:$literal_directory}"

if ! "$cozy_tmux" has-session -t "=$session" 2>/dev/null; then
  if creation_error=$("$cozy_tmux" new-session -d -s "$session" -n editor -c "$literal_directory" "$cozy_editor" 2>&1); then
    "$cozy_tmux" new-window -d -t "$session:" -n shell -c "$literal_directory" "$cozy_shell"
    "$cozy_tmux" new-window -d -t "$session:" -n git -c "$literal_directory" "$cozy_git"
    "$cozy_tmux" new-window -d -t "$session:" -n containers -c "$literal_directory" "$cozy_containers"
  elif ! "$cozy_tmux" has-session -t "=$session" 2>/dev/null; then
    printf '%s\n' "$creation_error" >&2
    exit 1
  fi
fi

if test -n "${TMUX:-}"; then
  exec "$cozy_tmux" switch-client -t "=$session"
fi
exec "$cozy_tmux" attach-session -t "=$session"
