#!/bin/bash
# Writes dist/image.json for the release TAG from the checksums in dist/.
#
# Usage: image_manifest.sh TAG
set -euo pipefail

tag=$1
base="https://github.com/limanix/modules/releases/download/$tag"

checksum() {
  cut -d ' ' -f 1 "dist/limanix-$1.qcow2.sha256"
}

jq -n --arg tag "$tag" --arg base "$base" \
  --arg aarch64 "$(checksum aarch64)" --arg x86_64 "$(checksum x86_64)" '{
  version: $tag,
  systems: {
    "aarch64-linux": { url: "\($base)/limanix-aarch64.qcow2", sha256: $aarch64 },
    "x86_64-linux": { url: "\($base)/limanix-x86_64.qcow2", sha256: $x86_64 }
  }
}' > dist/image.json
