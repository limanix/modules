#!/usr/bin/env bash
# Keep only outputs listed by the publishing run in CACHE/.live; builds of
# older versions leave the cache. Runs on the host before the cache is saved.
set -euo pipefail
shopt -s nullglob

cache=${1:?Usage: prune_nix_cache.sh CACHE_DIRECTORY}
live=$cache/.live
if ! test -f "$live"; then
  printf 'prune-nix-cache: no live list; cache unchanged\n' >&2
  exit 0
fi

declare -A keep=() nars=()
while IFS= read -r path; do
  test -n "$path" || continue
  if test "$path" = '*'; then
    rm -f -- "$live"
    printf 'prune-nix-cache: incomplete live list; cache unchanged\n' >&2
    exit 0
  fi
  name=${path#/nix/store/}
  keep[${name%%-*}]=1
done < "$live"

for narinfo in "$cache"/*.narinfo; do
  hash=${narinfo##*/}
  hash=${hash%.narinfo}
  if test -n "${keep[$hash]:-}"; then
    while IFS= read -r line; do
      case "$line" in 'URL: '*) nars[${line#URL: }]=1 ;; esac
    done < "$narinfo"
  else
    rm -f -- "$narinfo"
  fi
done
for nar in "$cache"/nar/*; do
  test -n "${nars[nar/${nar##*/}]:-}" || rm -f -- "$nar"
done
rm -f -- "$live"
