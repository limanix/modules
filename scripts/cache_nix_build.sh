#!/usr/bin/env bash
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
mkdir "$cache/.export-lock" 2>/dev/null || skip 'another export is active'
trap 'rmdir "$cache/.export-lock" 2>/dev/null || true' EXIT

# Reserve the closure's uncompressed size within a fixed 256 MiB archive limit.
maximum=268435456
sizes=$(timeout --kill-after=5s 30 nix path-info --recursive --size "${outputs[@]}") ||
  skip 'could not read closure sizes'
closure=0
while read -r path size extra; do
  [[ "$size" =~ ^[0-9]+$ && ${#size} -lt 19 && -z "$extra" ]] || skip 'invalid closure size'
  closure=$((closure + size))
  ((closure <= maximum)) || skip 'closure exceeds 256 MiB'
done <<< "$sizes"
usage=$(du -sb "$cache") || skip 'could not read cache size'
read -r stored _ <<< "$usage"
[[ "$stored" =~ ^[0-9]+$ && ${#stored} -lt 19 ]] || skip 'invalid cache size'
((stored + closure <= maximum)) || skip 'cache would exceed 256 MiB'

# Encode URL delimiters; quoted shell arguments preserve literal cache paths.
uri=${cache//%/%25}
uri=${uri// /%20}
uri=${uri//\#/%23}
uri=${uri//\?/%3F}
uri=${uri//\&/%26}
uri=${uri//+/%2B}
timeout --kill-after=5s 120 nix copy \
  --to "file://$uri?compression=zstd&compression-level=1" "${outputs[@]}" ||
  skip 'nix copy failed or timed out'
