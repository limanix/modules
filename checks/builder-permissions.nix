{ pkgs }:
pkgs.runCommand "contract-builder-permissions" { } ''
  printf 'Checking Nix builder privileges: uid=%s\n' "$EUID"
  if test "$EUID" = 0; then
    printf 'Nix smoke builds require an unprivileged builder\n' >&2
    exit 1
  fi

  readonly_output="$TMPDIR/readonly-output"
  printf 'original\n' > "$readonly_output"
  chmod 0444 "$readonly_output"
  if printf 'changed\n' 2>/dev/null > "$readonly_output"; then
    printf 'Nix builder bypassed a read-only file permission\n' >&2
    exit 1
  fi
  test "$(cat "$readonly_output")" = original

  # Unsandboxed Nix builds require this global HOME to stay absent.
  test "$HOME" = /homeless-shelter
  test ! -e "$HOME"
  if mkdir "$HOME" 2>/dev/null; then
    printf 'Nix builder created the global HOME\n' >&2
    exit 1
  fi
  test ! -e "$HOME"
  printf 'readonly=enforced home=unwritable\n' > "$out"
''
