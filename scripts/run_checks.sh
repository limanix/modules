#!/usr/bin/env bash
set -euo pipefail
set -f

mode=${1:?Specify modules or common}
shift
jobs=${NIX_CHECK_JOBS:-2}
batch_size=${NIX_CHECK_BATCH_SIZE:-4}

case "$mode" in
  modules|common) ;;
  *) printf 'Unsupported check mode: %s\n' "$mode" >&2; exit 2 ;;
esac
for value in "$jobs" "$batch_size" "${NIX_BUILD_CORES:-1}"; do
  if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Check jobs, batch size, and build cores must be positive integers\n' >&2
    exit 2
  fi
done
profile=pr
if test "$mode" = common; then
  profile=${1:-pr}
  (($# == 0)) || shift
  case "$profile" in
    pr|release) ;;
    *) printf 'Unsupported common check mode: %s\n' "$profile" >&2; exit 2 ;;
  esac
  if (($#)); then
    printf 'Common checks accept only pr or release\n' >&2
    exit 2
  fi
fi
# Module names follow the catalog grammar; no shell or Nix expressions are accepted.
requested=()
for argument in "$@"; do
  for name in $argument; do
    if [[ ! "$name" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]] || ((${#name} > 63)); then
      printf 'Invalid module name: %s\n' "$name" >&2
      exit 2
    fi
    requested+=("$name")
  done
done
json_modules() {
  local separator='' name
  printf '['
  for name in "$@"; do
    printf '%s"%s"' "$separator" "$name"
    separator=,
  done
  printf ']'
}

if test -n "${NIX_BUILD_CACHE:-}"; then
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

system=$(nix eval --raw --impure --expr builtins.currentSystem)
case "$system" in
  x86_64-linux|aarch64-linux) ;;
  *) printf 'Module checks require a native Linux runner: %s\n' "$system" >&2; exit 2 ;;
esac
run_diagnostics() {
  local file=$1 output=$2 name expected
  shift 2
  nix eval --raw --impure --file "$file" diagnostics "$@" \
    --apply 'checks: builtins.concatStringsSep "\n" (map
      (name: name + "\t" + checks.${name}.expected) (builtins.attrNames checks)) + "\n"' \
    > "$output/cases"
  while IFS=$'\t' read -r name expected; do
    test -n "$name" || continue
    test -n "$expected"
    printf 'Checking expected diagnostic: %s\n' "$name"
    if nix eval --json --show-trace --impure \
      --option allow-import-from-derivation false \
      --file "$file" "$@" \
      "diagnostics.\"$name\".actual" > "$output/stdout" 2> "$output/stderr"; then
      printf 'Expected %s to fail, but it succeeded\n' "$name" >&2
      return 1
    fi
    if ! grep -F -- "$expected" "$output/stderr" > /dev/null; then
      cat "$output/stderr" >&2
      printf 'Missing expected diagnostic: %s\n' "$expected" >&2
      return 1
    fi
  done < "$output/cases"
}

cores=${NIX_BUILD_CORES:-$(( $(nproc) / jobs ))}
((cores > 0)) || cores=1
build_jobs=$jobs
realise_smoke() {
  local output=$1 label=$2
  local -a derivations
  sort -u "$output/derivations" > "$output/unique-derivations"
  mapfile -t derivations < "$output/unique-derivations"
  if ((${#derivations[@]})); then
    printf 'Realising %s distinct smoke derivations for %s\n' "${#derivations[@]}" "$label"
    nix-store --realise --option build-users-group nixbld \
      --max-jobs "$build_jobs" --cores "$cores" "${derivations[@]}"
  fi
}

if test "$mode" = common; then
  started=$SECONDS
  printf 'Checking common %s on %s\n' "$profile" "$system"
  nix eval --json --show-trace --impure \
    --option allow-import-from-derivation false \
    --file checks/common.nix all
  run_diagnostics checks/common.nix "$temporary"
  if test "$profile" = release; then
    nix eval --raw --impure --file checks/integration.nix evaluation \
      --apply 'checks: builtins.concatStringsSep "\n" (builtins.attrNames checks) + "\n"' \
      > "$temporary/integration-cases"
    while IFS= read -r case_name; do
      printf 'Checking catalog integration: %s\n' "$case_name"
      nix eval --json --show-trace --impure \
        --option allow-import-from-derivation false \
        --file checks/integration.nix "evaluation.\"$case_name\"" \
        --apply 'value: builtins.deepSeq value true'
    done < "$temporary/integration-cases"
    nix-instantiate checks/integration.nix --show-trace --attr smoke \
      --option allow-import-from-derivation false > "$temporary/derivations"
    realise_smoke "$temporary" 'common release'
  fi
  printf 'Passed common %s on %s in %ss\n' "$profile" "$system" "$((SECONDS - started))"
  exit 0
fi

selected_json=$(json_modules "${requested[@]}")
nix eval --raw --impure --file checks/modules.nix names \
  --argstr modules "$selected_json" \
  --apply 'names: builtins.concatStringsSep "\n" names' > "$temporary/modules"
mapfile -t modules < "$temporary/modules"
test "${#modules[@]}" -gt 0
workers=$(( (${#modules[@]} + batch_size - 1) / batch_size ))
((workers <= jobs)) || workers=$jobs
build_jobs=$((jobs / workers))

run_batch() {
  local identifier=$1 name selection started
  shift
  local output="$temporary/$identifier"
  mkdir "$output"
  for name in "$@"; do
    started=$SECONDS
    selection=$(json_modules "$name")
    printf 'Checking %s on %s: %s\n' "$mode" "$system" "$name"
    # Each module shares evaluation and smoke configurations, then releases its evaluator.
    nix-instantiate checks/modules.nix --show-trace --attr all \
      --option allow-import-from-derivation false \
      --argstr modules "$selection" > "$output/derivations"
    run_diagnostics checks/modules.nix "$output" --argstr modules "$selection"
    realise_smoke "$output" "$name"
    printf 'Passed %s on %s in %ss\n' "$name" "$system" "$((SECONDS - started))"
  done
}

# Parallel module batches are bounded independently of the number of selectors.
# In CI each job receives at most four module names from the change planner.
started=$SECONDS
offset=0
while ((offset < ${#modules[@]} || ${#active_pids[@]})); do
  while ((offset < ${#modules[@]} && ${#active_pids[@]} < workers)); do
    count=$batch_size
    if ((offset + count > ${#modules[@]})); then
      count=$((${#modules[@]} - offset))
    fi
    run_batch "$offset" "${modules[@]:offset:count}" &
    active_pids+=("$!")
    offset=$((offset + count))
  done
  status=0
  finished=''
  wait -n -p finished "${active_pids[@]}" || status=$?
  test "$status" -eq 0 || exit "$status"
  if test -z "${finished:-}"; then
    printf 'No active module batch returned a result\n' >&2
    exit 1
  fi
  remaining=()
  for pid in "${active_pids[@]}"; do
    test "$pid" = "$finished" || remaining+=("$pid")
  done
  active_pids=("${remaining[@]}")
done
printf 'Passed %s module suites on %s in %ss\n' "${#modules[@]}" "$system" "$((SECONDS - started))"
