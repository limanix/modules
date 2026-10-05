#!/usr/bin/env bash
set -uf

skip() {
  printf 'cache-nix-build: skipping optional cache: %s\n' "$*" >&2
  exit 0
}

read_output_paths() {
  IFS=$' \t\n' read -r -a output_paths <<< "${OUT_PATHS:-}"
  if ((${#output_paths[@]} == 0)); then
    exit 0
  fi

  local output_path
  for output_path in "${output_paths[@]}"; do
    case "$output_path" in
      /*) ;;
      *) skip 'output path must be absolute' ;;
    esac
  done
}

copy_outputs_to_cache() {
  local cache_uri=${cache_directory//%/%25}
  cache_uri=${cache_uri// /%20}
  cache_uri=${cache_uri//\#/%23}
  cache_uri=${cache_uri//\?/%3F}
  cache_uri=${cache_uri//\&/%26}
  cache_uri=${cache_uri//+/%2B}

  if ! timeout --kill-after=5s 120 nix copy \
    --to "file://$cache_uri?compression=zstd&compression-level=1" "${output_paths[@]}"; then
    skip 'nix copy failed or timed out'
  fi
}

main() {
  cache_directory=${NIX_BUILD_CACHE:-}
  case "$cache_directory" in
    /*) ;;
    *) skip 'cache path must be absolute' ;;
  esac

  read_output_paths
  if ! mkdir -p "$cache_directory"; then
    skip 'cache directory is not writable'
  fi
  copy_outputs_to_cache
}

main
