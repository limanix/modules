#!/usr/bin/env bash
# Post-build hook: export the outputs Nix has just built locally.
# A binary cache must hold every reference of its paths, so the copy includes
# the runtime closure; paths already in the cache are skipped.
# Optional exports never change a successful build's result.
set -uf

skip() {
  printf 'cache-nix-build: skipping optional cache: %s\n' "$*" >&2
  exit 0
}

cache=${NIX_BUILD_CACHE:-}
case "$cache" in /*) ;; *) skip 'cache path must be absolute' ;; esac
# Nix store paths cannot contain whitespace.
IFS=$' \t\n' read -r -a outputs <<< "${OUT_PATHS:-}"
((${#outputs[@]})) || exit 0
for path in "${outputs[@]}"; do
  case "$path" in /*) ;; *) skip 'output path must be absolute' ;; esac
done
mkdir -p "$cache" || skip 'cache directory is not writable'

# Encode URL delimiters; quoted shell arguments preserve literal cache paths.
uri=${cache//%/%25}
uri=${uri// /%20}
uri=${uri//\#/%23}
uri=${uri//\?/%3F}
uri=${uri//\&/%26}
uri=${uri//+/%2B}
# Nix waits for the hook, so a stuck copy must not hold the build.
timeout --kill-after=5s 120 nix copy \
  --to "file://$uri?compression=zstd&compression-level=1" "${outputs[@]}" ||
  skip 'nix copy failed or timed out'
