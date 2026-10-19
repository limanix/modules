#!/bin/bash
# Prints the GitHub output tag=v<N> for the next release, or nothing when HEAD is tagged already.
#
# Usage: next_tag.sh >> "$GITHUB_OUTPUT"
set -euo pipefail

if git tag --points-at HEAD | grep -qE '^v[1-9][0-9]*$'; then
  echo "HEAD is released already" >&2
  echo "tag="
  exit 0
fi

last=$(git tag --list 'v*' | grep -E '^v[1-9][0-9]*$' | sort -t v -k 2 -n | tail -n 1 || true)
echo "tag=v$((${last#v} + 1))"
