#!/bin/bash
# Keeps one open "Catalog drift" issue with the report of scripts/drift.nix: it opens the issue when
# lines drift from their sources, updates it while they do and closes it once they match again.
#
# Usage: report_drift.sh
set -euo pipefail

title='Catalog drift'
report=$(nix eval --json --impure --file scripts/drift.nix)
findings=$(jq -r .findings <<< "$report")
body=$(jq -r .markdown <<< "$report")
number=$(gh issue list --repo "$GITHUB_REPOSITORY" --state open --json number,title \
  --jq "map(select(.title == \"$title\")) | first | .number // empty")

if [ "$findings" -gt 0 ]; then
  if [ -n "$number" ]; then
    gh issue edit "$number" --repo "$GITHUB_REPOSITORY" --body "$body"
  else
    gh issue create --repo "$GITHUB_REPOSITORY" --title "$title" --body "$body"
  fi
elif [ -n "$number" ]; then
  gh issue close "$number" --repo "$GITHUB_REPOSITORY" --comment "$body"
fi
echo "Catalog drift: $findings finding(s)" >&2
