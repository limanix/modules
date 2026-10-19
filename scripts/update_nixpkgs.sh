#!/bin/bash
# Updates Nixpkgs within its NixOS release and prints GitHub outputs: the release, and the
# Nixpkgs revision and its date before and after.
#
# Usage: update_nixpkgs.sh >> "$GITHUB_OUTPUT"
set -euo pipefail

revision() {
  jq -r '.nodes.nixpkgs.locked.rev' flake.lock
}
revision_date() {
  jq -r '.nodes.nixpkgs.locked.lastModified | strftime("%Y%m%d")' flake.lock
}

release=$(sed -nE 's#.*"github:NixOS/nixpkgs/nixos-([0-9]{2}\.[0-9]{2})".*#\1#p' flake.nix)
before=$(revision)
nix flake update nixpkgs
after=$(revision)
echo "Nixpkgs $release: $before -> $after" >&2

echo "release=$release"
echo "before=${before:0:7}"
echo "after=${after:0:7}"
echo "date=$(revision_date)"
