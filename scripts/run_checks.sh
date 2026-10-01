#!/usr/bin/env bash
set -euo pipefail

mode=${1:?Specify eval or smoke}
arch=${2:-}

case "$arch" in
  ''|amd64|arm64) ;;
  *) printf 'Unsupported architecture: %s\n' "$arch" >&2; exit 2 ;;
esac

case "$mode" in
  eval)
    check_arches=${arch:-'amd64 arm64'}
    temporary=$(mktemp -d)
    trap 'rm -rf "$temporary"' EXIT

    evaluate_configuration() {
      local attribute=$1 children child
      # One process per leaf avoids retaining every evaluated NixOS configuration.
      children=$(nix eval --show-trace --raw \
        --option allow-import-from-derivation false \
        --file checks/default.nix "$attribute" \
        --apply 'value: if builtins.isAttrs value then
          builtins.concatStringsSep "\n" (map builtins.toJSON (builtins.attrNames value))
          else builtins.seq (builtins.toJSON value) ""')
      while IFS= read -r child; do
        test -n "$child" || continue
        evaluate_configuration "$attribute.$child"
      done <<< "$children"
    }

    for check_arch in $check_arches; do
      case "$check_arch" in
        amd64) system=x86_64-linux ;;
        arm64) system=aarch64-linux ;;
      esac
      printf 'Evaluating catalog configuration checks for %s\n' "$system"
      evaluate_configuration "$check_arch"

      cases=$(nix eval --raw --impure --expr "import ./checks/negative.nix { system = \"$system\"; }" \
        --apply 'checks: builtins.concatStringsSep "\n" (builtins.attrNames checks)')
      while IFS= read -r check; do
        test -n "$check" || continue
        expected=$(nix eval --raw --file checks/negative.nix \
          --argstr system "$system" "$check.expected")
        test -n "$expected"
        printf 'Checking expected diagnostic for %s: %s\n' "$system" "$check"
        if nix eval --show-trace --json \
          --option allow-import-from-derivation false \
          --file checks/negative.nix --argstr system "$system" "$check.actual" \
          > "$temporary/stdout" 2> "$temporary/stderr"; then
          printf 'Expected %s to fail on %s, but it succeeded\n' "$check" "$system" >&2
          exit 1
        fi
        if ! grep -F -- "$expected" "$temporary/stderr" > /dev/null; then
          cat "$temporary/stderr" >&2
          printf 'Missing expected diagnostic: %s\n' "$expected" >&2
          exit 1
        fi
      done <<< "$cases"
    done
    ;;
  smoke)
    system=$(nix eval --raw --impure --expr builtins.currentSystem)
    case "$system" in
      x86_64-linux) native_arch=amd64 ;;
      aarch64-linux) native_arch=arm64 ;;
      *) printf 'Unsupported smoke runner system: %s\n' "$system" >&2; exit 2 ;;
    esac
    if test -n "$arch" && test "$arch" != "$native_arch"; then
      printf 'Smoke checks require a native %s Linux runner; this runner is %s\n' "$arch" "$system" >&2
      exit 2
    fi
    printf 'Building and running catalog smoke checks for %s\n' "$system"
    selectors=$(nix eval --raw --impure \
      --expr 'builtins.concatStringsSep "\n" (map builtins.toJSON (builtins.attrNames (import ./checks/smoke.nix { })))')
    while IFS= read -r selector; do
      test -n "$selector" || continue
      cases=$(nix eval --raw --impure \
        --expr "builtins.getAttr $selector (import ./checks/smoke.nix { })" \
        --apply 'checks: builtins.concatStringsSep "\n" (map builtins.toJSON (builtins.attrNames checks))')
      while IFS= read -r check; do
        test -n "$check" || continue
        # Build one discovered check without retaining all configurations in one evaluator.
        nix-build checks/smoke.nix --no-out-link --show-trace \
          --option allow-import-from-derivation false -A "$selector.$check"
      done <<< "$cases"
    done <<< "$selectors"
    ;;
  *) printf 'Unsupported check mode: %s\n' "$mode" >&2; exit 2 ;;
esac
