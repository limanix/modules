#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

read_live_store_hashes() {
  local store_path store_name
  while IFS= read -r store_path; do
    test -n "$store_path" || continue
    if test "$store_path" = '*'; then
      rm -f -- "$live_paths_file"
      printf 'prune-nix-cache: incomplete live list; cache unchanged\n' >&2
      exit 0
    fi
    store_name=${store_path#/nix/store/}
    live_store_hashes[${store_name%%-*}]=1
  done < "$live_paths_file"
}

prune_narinfo_files() {
  local narinfo_file store_hash line
  for narinfo_file in "$cache_directory"/*.narinfo; do
    store_hash=${narinfo_file##*/}
    store_hash=${store_hash%.narinfo}
    if test -n "${live_store_hashes[$store_hash]:-}"; then
      while IFS= read -r line; do
        case "$line" in
          'URL: '*) referenced_nar_paths[${line#URL: }]=1 ;;
        esac
      done < "$narinfo_file"
    else
      rm -f -- "$narinfo_file"
    fi
  done
}

prune_nar_files() {
  local nar_file
  for nar_file in "$cache_directory"/nar/*; do
    if test -z "${referenced_nar_paths[nar/${nar_file##*/}]:-}"; then
      rm -f -- "$nar_file"
    fi
  done
}

main() {
  cache_directory=${1:?Usage: prune_nix_cache.sh CACHE_DIRECTORY}
  live_paths_file=$cache_directory/.live
  if ! test -f "$live_paths_file"; then
    printf 'prune-nix-cache: no live list; cache unchanged\n' >&2
    return 0
  fi

  declare -A live_store_hashes=() referenced_nar_paths=()
  read_live_store_hashes
  prune_narinfo_files
  prune_nar_files
  rm -f -- "$live_paths_file"
}

main "$@"
