#!/usr/bin/env bash
set -euo pipefail
set -f
IFS=' '

# Nix supplies space-separated store paths; they cannot contain whitespace.
# Export complete runtime closures so every reference can be substituted.
# shellcheck disable=SC2086
exec nix copy \
  --to "file://${NIX_BUILD_CACHE:?}?compression=zstd&compression-level=1&parallel-compression=false" \
  $OUT_PATHS
