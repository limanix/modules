#!/usr/bin/env bash
set -euo pipefail

mode=${1:?Specify eval, smoke, or all}
arch=${2:-}
jobs=${NIX_CHECK_JOBS:-2}
batch_size=${NIX_CHECK_BATCH_SIZE:-8}

case "$arch" in
  ''|amd64|arm64) ;;
  *) printf 'Unsupported architecture: %s\n' "$arch" >&2; exit 2 ;;
esac
case "$mode" in
  eval|smoke|all) ;;
  *) printf 'Unsupported check mode: %s\n' "$mode" >&2; exit 2 ;;
esac
for value in "$jobs" "$batch_size" "${NIX_BUILD_CORES:-1}"; do
  if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Check jobs, batch size, and build cores must be positive integers\n' >&2
    exit 2
  fi
done

if test -n "${NIX_BUILD_CACHE:-}" && { test "$mode" != all || ((jobs == 1)); }; then
  case "$NIX_BUILD_CACHE" in
    /*) ;;
    *) printf 'NIX_BUILD_CACHE must be an absolute directory\n' >&2; exit 2 ;;
  esac
  mkdir -p "$NIX_BUILD_CACHE"
  export NIX_BUILD_CACHE
  export NIX_CONFIG="${NIX_CONFIG:-}
extra-substituters = file://$NIX_BUILD_CACHE?trusted=1
post-build-hook = $PWD/scripts/cache_nix_build.sh"
fi

temporary=$(mktemp -d)
active_pids=()
cleanup() {
  trap - EXIT INT TERM
  if ((${#active_pids[@]})); then
    kill "${active_pids[@]}" 2>/dev/null || true
    for pid in "${active_pids[@]}"; do
      wait "$pid" 2>/dev/null || true
    done
  fi
  rm -rf "$temporary"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Inputs are JSON strings or paths emitted by Nix, not shell expressions.
json_array() {
  local separator='' value
  printf '['
  for value in "$@"; do
    printf '%s%s' "$separator" "$value"
    separator=,
  done
  printf ']'
}

# Fill each freed evaluator slot immediately. Keep result order deterministic,
# even when batches finish out of order, and retain each batch's diagnostics.
run_batches() {
  local kind=$1 input=$2 output=$3 system=${4:-}
  local offset=0 count id pid finished status value
  local -a pending outputs remaining
  local -A identifiers started
  mapfile -t pending < "$input"
  outputs=() active_pids=()
  : > "$output"
  while ((offset < ${#pending[@]} || ${#active_pids[@]})); do
    while ((offset < ${#pending[@]} && ${#active_pids[@]} < jobs)); do
      id=$offset
      count=$batch_size
      if ((id + count > ${#pending[@]})); then
        count=$((${#pending[@]} - id))
      fi
      outputs+=("$temporary/batch-$id.out")
      printf '%s batch %s-%s of %s\n' "$kind" "$((id + 1))" "$((id + count))" "${#pending[@]}"
      if test "$kind" = eval; then
        nix eval --show-trace --raw \
          --option allow-import-from-derivation false \
          --file checks/eval-batch.nix result \
          --argstr paths "$(json_array "${pending[@]:id:count}")" \
          > "$temporary/batch-$id.out" 2> "$temporary/batch-$id.err" &
      else
        nix-instantiate checks/smoke-batch.nix --show-trace \
          --option allow-import-from-derivation false \
          --argstr system "$system" \
          --argstr selectors "$(json_array "${pending[@]:id:count}")" \
          > "$temporary/batch-$id.out" 2> "$temporary/batch-$id.err" &
      fi
      pid=$!
      active_pids+=("$pid")
      identifiers[$pid]=$id
      started[$pid]=$SECONDS
      offset=$((offset + count))
    done
    status=0
    finished=''
    wait -n -p finished "${active_pids[@]}" || status=$?
    if test -z "${finished:-}"; then
      printf 'No active evaluator returned a result\n' >&2
      return 1
    fi
    id=${identifiers[$finished]}
    cat "$temporary/batch-$id.err" >&2
    printf '%s batch starting at %s finished in %ss\n' \
      "$kind" "$((id + 1))" "$((SECONDS - started[$finished]))"
    remaining=()
    for pid in "${active_pids[@]}"; do
      test "$pid" = "$finished" || remaining+=("$pid")
    done
    active_pids=("${remaining[@]}")
    test "$status" -eq 0 || return "$status"
  done
  for value in "${outputs[@]}"; do
    cat "$value" >> "$output"
    printf '\n' >> "$output"
  done
}

run_eval() {
  local check_arch system kind value cases check expected started total
  for check_arch in ${arch:-amd64 arm64}; do
    case "$check_arch" in
      amd64) system=x86_64-linux ;;
      arm64) system=aarch64-linux ;;
    esac
    started=$SECONDS
    total=0
    printf 'Evaluating catalog configuration checks for %s\n' "$system"
    printf '["%s"]\n' "$check_arch" > "$temporary/frontier"
    while test -s "$temporary/frontier"; do
      run_batches eval "$temporary/frontier" "$temporary/results"
      : > "$temporary/next"
      while IFS=$'\t' read -r kind value; do
        case "$kind" in
          group) printf '%s\n' "$value" >> "$temporary/next" ;;
          passed) printf 'Passed %s\n' "$value"; total=$((total + 1)) ;;
          '') ;;
          *) printf 'Invalid check result: %s\n' "$kind" >&2; return 1 ;;
        esac
      done < "$temporary/results"
      mv "$temporary/next" "$temporary/frontier"
    done

    # Only the expected text is evaluated together. Each failure must still come
    # from its own evaluator and contain the diagnostic declared by that case.
    # ${name} belongs to the Nix expression, not to the shell.
    # shellcheck disable=SC2016
    cases=$(nix eval --raw --impure --expr "import ./checks/negative.nix { system = \"$system\"; }" \
      --apply 'checks: builtins.concatStringsSep "\n" (map
        (name: name + "\t" + checks.${name}.expected) (builtins.attrNames checks))')
    while IFS=$'\t' read -r check expected; do
      test -n "$check" || continue
      test -n "$expected"
      printf 'Checking expected diagnostic for %s: %s\n' "$system" "$check"
      if nix eval --show-trace --json \
        --option allow-import-from-derivation false \
        --file checks/negative.nix --argstr system "$system" "$check.actual" \
        > "$temporary/stdout" 2> "$temporary/stderr"; then
        printf 'Expected %s to fail on %s, but it succeeded\n' "$check" "$system" >&2
        return 1
      fi
      if ! grep -F -- "$expected" "$temporary/stderr" > /dev/null; then
        cat "$temporary/stderr" >&2
        printf 'Missing expected diagnostic: %s\n' "$expected" >&2
        return 1
      fi
      total=$((total + 1))
    done <<< "$cases"
    printf 'Evaluated %s checks for %s in %ss\n' "$total" "$system" "$((SECONDS - started))"
  done
}

run_smoke() {
  local system native_arch started count cores
  local -a derivations
  system=$(nix eval --raw --impure --expr builtins.currentSystem)
  case "$system" in
    x86_64-linux) native_arch=amd64 ;;
    aarch64-linux) native_arch=arm64 ;;
    *) printf 'Unsupported smoke runner system: %s\n' "$system" >&2; return 2 ;;
  esac
  if test -n "$arch" && test "$arch" != "$native_arch"; then
    printf 'Smoke checks require a native %s Linux runner; this runner is %s\n' "$arch" "$system" >&2
    return 2
  fi
  started=$SECONDS
  printf 'Building and running catalog smoke checks for %s\n' "$system"
  nix eval --raw --impure \
    --expr 'builtins.concatStringsSep "\n" (map builtins.toJSON (builtins.attrNames (import ./checks/smoke.nix { })))' \
    > "$temporary/selectors"
  run_batches smoke "$temporary/selectors" "$temporary/derivations" "$system"
  count=$(grep -c '^/nix/store/.*\.drv$' "$temporary/derivations")
  mapfile -t derivations < <(grep -v '^$' "$temporary/derivations" | sort -u)
  printf 'Instantiated %s smoke checks, %s unique derivations, in %ss\n' \
    "$count" "${#derivations[@]}" "$((SECONDS - started))"
  test "${#derivations[@]}" -gt 0
  cores=${NIX_BUILD_CORES:-$(( $(nproc) / jobs ))}
  ((cores > 0)) || cores=1
  # The CI image disables build users by default. Its nixbld accounts keep
  # package permission checks meaningful even though Nix manages the store as root.
  nix-store --realise --option build-users-group nixbld \
    --max-jobs "$jobs" --cores "$cores" "${derivations[@]}" &
  active_pids=("$!")
  wait "${active_pids[0]}"
  active_pids=()
  printf 'Built and ran smoke checks for %s in %ss\n' "$system" "$((SECONDS - started))"
}

run_all() {
  local cores pid finished status started=$SECONDS
  local -a remaining
  if ((jobs == 1)); then
    run_eval
    run_smoke
  else
    # Independent stages share the store and a divided CPU budget; each child
    # owns its temporary plan. A failure ends the other stage through cleanup.
    cores=${NIX_BUILD_CORES:-$(( $(nproc) / jobs ))}
    ((cores > 0)) || cores=1
    NIX_CHECK_JOBS=$((jobs - jobs / 2)) bash "$0" eval "$arch" &
    active_pids=("$!")
    NIX_CHECK_JOBS=$((jobs / 2)) NIX_BUILD_CORES=$cores bash "$0" smoke "$arch" &
    active_pids+=("$!")
    while ((${#active_pids[@]})); do
      status=0
      finished=''
      wait -n -p finished "${active_pids[@]}" || status=$?
      test "$status" -eq 0 || return "$status"
      if test -z "${finished:-}"; then
        printf 'No active check stage returned a result\n' >&2
        return 1
      fi
      remaining=()
      for pid in "${active_pids[@]}"; do
        test "$pid" = "$finished" || remaining+=("$pid")
      done
      active_pids=("${remaining[@]}")
    done
  fi
  printf 'Catalog evaluation and smoke finished in %ss\n' "$((SECONDS - started))"
}

case "$mode" in
  eval) run_eval ;;
  smoke) run_smoke ;;
  all) run_all ;;
esac
