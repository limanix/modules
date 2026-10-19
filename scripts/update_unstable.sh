#!/bin/bash
# Moves the catalog's nixos-unstable revision in catalog/_shared/unstable.toml to the channel's
# newest one and prints GitHub outputs: the revision before and after, and the new revision's date.
# It needs only Bash, curl and Nix: the ci/nix container has no sed or jq.
#
# Usage: update_unstable.sh >> "$GITHUB_OUTPUT"
set -euo pipefail

file=catalog/_shared/unstable.toml
before=''
while IFS= read -r line; do
  if [[ $line =~ ^rev\ =\ \"([0-9a-f]{40})\"$ ]]; then
    before=${BASH_REMATCH[1]}
  fi
done < "$file"
after=$(curl -fsSL https://channels.nixos.org/nixos-unstable/git-revision)

if [ "$after" != "$before" ]; then
  prefetch=$(nix flake prefetch --json "github:NixOS/nixpkgs/$after")
  [[ $prefetch =~ \"hash\":\"([^\"]+)\" ]]
  hash=${BASH_REMATCH[1]}
  [[ $prefetch =~ \"lastModified\":([0-9]+) ]]
  modified=${BASH_REMATCH[1]}

  updated=''
  while IFS= read -r line; do
    case $line in
      'rev = '*) line="rev = \"$after\"" ;;
      'sha256 = '*) line="sha256 = \"$hash\"" ;;
    esac
    updated+="$line"$'\n'
  done < "$file"
  printf '%s' "$updated" > "$file"
  echo "nixos-unstable: $before -> $after" >&2
  TZ=UTC printf 'date=%(%Y%m%d)T\n' "$modified"
fi

echo "before=${before:0:7}"
echo "after=${after:0:7}"
