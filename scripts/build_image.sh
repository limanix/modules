#!/bin/sh
# Builds the base disk: dist/limanix-<arch>.qcow2 and its .sha256.
# `task release/build` runs it from the repository root in the ci/nix container.
#
# Usage: build_image.sh ARCH
set -eu

arch=$1

# The checkout belongs to the host user; Nix reads it as root.
git config --global --add safe.directory "$PWD"
nix() {
  command nix --extra-experimental-features 'nix-command flakes' --option build-users-group nixbld "$@"
}

name="limanix-$arch"
out=$(nix build --no-link --print-out-paths --print-build-logs ".#packages.$arch-linux.image")

mkdir -p dist
rm -f "dist/$name.qcow2" "dist/$name.qcow2.sha256"
cp "$out" "dist/$name.qcow2"
chmod 0644 "dist/$name.qcow2"
(cd dist && sha256sum "$name.qcow2" > "$name.qcow2.sha256")
