#!/bin/bash
# Moves Nixpkgs to the next NixOS release once its channel is published, and prints GitHub
# outputs: the current release, and the next one or nothing when it is not published yet.
#
# Usage: update_nixos.sh >> "$GITHUB_OUTPUT"
set -euo pipefail

current=$(sed -nE 's#.*"github:NixOS/nixpkgs/nixos-([0-9]{2}\.[0-9]{2})".*#\1#p' flake.nix)
year=${current%.*}
case ${current#*.} in
  05) next="$year.11" ;;
  11) next="$((10#$year + 1)).05" ;;
  *)
    echo "Unexpected NixOS release $current" >&2
    exit 1
    ;;
esac

echo "current=$current"
if ! curl -fsSL -o /dev/null "https://channels.nixos.org/nixos-$next/git-revision"; then
  echo "NixOS $next is not published yet" >&2
  echo "next="
  exit 0
fi

sed -i "s#nixpkgs/nixos-$current\"#nixpkgs/nixos-$next\"#" flake.nix
nix flake update nixpkgs
echo "NixOS $current -> $next" >&2
echo "next=$next"
