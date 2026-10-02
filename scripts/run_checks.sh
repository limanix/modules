#!/usr/bin/env bash
set -euo pipefail
set -f

arguments=("$@")
mode=${1:?Specify modules or common}
shift
# Full NixOS evaluations can use several GiB; keep local evaluators serial.
# Increase NIX_CHECK_JOBS only when the runner has enough memory.
jobs=${NIX_CHECK_JOBS:-1}
batch_size=${NIX_CHECK_BATCH_SIZE:-4}
timeout_seconds=${NIX_CHECK_TIMEOUT:-480}
runtime_profile=${NIX_RUNTIME_PROFILE:-all}
case "$runtime_profile" in
  all|pr) ;;
  *) printf 'Unsupported module runtime profile: %s\n' "$runtime_profile" >&2; exit 2 ;;
esac
if test "$mode" != modules && { test "$runtime_profile" != all || test -n "${NIX_RUNTIME_VERSIONS:-}"; }; then
  printf 'Runtime selections require module checks\n' >&2
  exit 2
fi
runtime_versions=()
for version in ${NIX_RUNTIME_VERSIONS:-}; do
  if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]] || ((${#version} > 63)); then
    printf 'Invalid runtime version: %s\n' "$version" >&2
    exit 2
  fi
  runtime_versions+=("$version")
done
if test "$runtime_profile" = all && ((${#runtime_versions[@]})); then
  printf 'Explicit runtime versions require the pr profile\n' >&2
  exit 2
fi

case "$mode" in
  modules|common) ;;
  *) printf 'Unsupported check mode: %s\n' "$mode" >&2; exit 2 ;;
esac
for value in "$jobs" "$batch_size" "${NIX_BUILD_CORES:-1}" "$timeout_seconds"; do
  if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Check jobs, batch size, build cores, and timeout must be positive integers\n' >&2
    exit 2
  fi
done
profile='pr'
if test "$mode" = common; then
  profile=${1:-pr}
  (($# == 0)) || shift
  case "$profile" in
    pr|release|release-eval|release-smoke) ;;
    *) printf 'Unsupported common check mode: %s\n' "$profile" >&2; exit 2 ;;
  esac
  if (($#)); then
    printf 'Common checks accept one profile: pr, release, release-eval or release-smoke\n' >&2
    exit 2
  fi
fi
integration_group=${NIX_INTEGRATION_GROUP:-all}
case "$integration_group" in
  all) ;;
  base|compositions|versions)
    if test "$mode" != common || { test "$profile" != release && test "$profile" != release-eval; }; then
      printf 'Integration groups require common release or release-eval\n' >&2
      exit 2
    fi
    ;;
  *) printf 'Unsupported integration group: %s\n' "$integration_group" >&2; exit 2 ;;
esac
# Bound the complete suite, including evaluation, builds and diagnostics.
# GNU timeout terminates the process group, covering Nix worker descendants.
if test "${_LIMANIX_CHECK_BOUNDED:-}" != 1; then
  command -v timeout >/dev/null || {
    printf 'Module checks require GNU timeout on the Linux runner\n' >&2
    exit 2
  }
  export _LIMANIX_CHECK_BOUNDED=1
  exec timeout --kill-after=15s "$timeout_seconds" bash "$0" "${arguments[@]}"
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
if ((${#runtime_versions[@]} && ${#requested[@]} != 1)); then
  printf 'Explicit runtime versions require exactly one module\n' >&2
  exit 2
fi
json_strings() {
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
  # Nix owns ${name}; keep shell expansion disabled in this expression.
  # shellcheck disable=SC2016
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
  local output=$1 label=$2 derivation
  local -a derivations=()
  sort -u "$output/derivations" > "$output/unique-derivations"
  while IFS= read -r derivation; do
    derivations+=("$derivation")
  done < "$output/unique-derivations"
  if ((${#derivations[@]})); then
    printf 'Realising %s distinct smoke derivations for %s\n' "${#derivations[@]}" "$label"
    local -a build_options=(--max-jobs "$build_jobs" --cores "$cores")
    if test "$(id -u)" = 0; then
      local build_users_group
      build_users_group=$(nix config show build-users-group)
      if test -z "$build_users_group"; then
        # The CI image has dedicated builders but disables them by default.
        # Root controls the store; fixtures and upstream checks must run unprivileged.
        build_options+=(--option build-users-group nixbld)
      fi
    fi
    nix-store --realise "${build_options[@]}" "${derivations[@]}"
  fi
}

if test "$mode" = common; then
  started=$SECONDS
  printf 'Checking common %s (%s) on %s\n' "$profile" "$integration_group" "$system"
  if test "$profile" != release-smoke && { test "$integration_group" = all || test "$integration_group" = base; }; then
    nix eval --json --show-trace --impure \
      --option allow-import-from-derivation false \
      --file checks/common.nix all
    run_diagnostics checks/common.nix "$temporary"
    nix-instantiate checks/common.nix --show-trace --attr smoke \
      --option allow-import-from-derivation false > "$temporary/derivations"
    realise_smoke "$temporary" "common $profile"
  fi
  if test "$profile" = release || test "$profile" = release-eval; then
    integration_attribute=evaluation
    if test "$integration_group" != all; then
      integration_attribute="evaluationGroups.\"$integration_group\""
    fi
    nix eval --raw --impure --file checks/integration.nix "$integration_attribute" \
      --apply 'checks: builtins.concatStringsSep "\n" (builtins.attrNames checks) + "\n"' \
      > "$temporary/integration-cases"
    while IFS= read -r case_name; do
      printf 'Checking catalog integration: %s\n' "$case_name"
      nix eval --json --show-trace --impure \
        --option allow-import-from-derivation false \
        --file checks/integration.nix "$integration_attribute.\"$case_name\"" \
        --apply 'value: builtins.deepSeq value true'
    done < "$temporary/integration-cases"
    if test "$integration_group" = all || test "$integration_group" = base; then
      run_diagnostics checks/integration.nix "$temporary"
    fi
  fi
  if test "$profile" = release || test "$profile" = release-smoke; then
    nix-instantiate checks/integration.nix --show-trace --attr smoke \
      --option allow-import-from-derivation false > "$temporary/derivations"
    realise_smoke "$temporary" 'common release'
  fi
  printf 'Passed common %s (%s) on %s in %ss\n' "$profile" "$integration_group" "$system" "$((SECONDS - started))"
  exit 0
fi

selected_json=$(json_strings "${requested[@]}")
runtime_arguments=(--argstr runtimeProfile "$runtime_profile" --argstr runtimeVersions "$(json_strings "${runtime_versions[@]}")")
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
    selection=$(json_strings "$name")
    printf 'Checking %s on %s: %s (runtime %s; additional versions: %s)\n' "$mode" "$system" "$name" "$runtime_profile" "${runtime_versions[*]:-none}"
    # Each module shares evaluation and smoke configurations, then releases its evaluator.
    nix-instantiate checks/modules.nix --show-trace --attr all \
      --option allow-import-from-derivation false \
      --argstr modules "$selection" "${runtime_arguments[@]}" > "$output/derivations"
    run_diagnostics checks/modules.nix "$output" --argstr modules "$selection" "${runtime_arguments[@]}"
    realise_smoke "$output" "$name"
    printf 'Passed %s on %s in %ss\n' "$name" "$system" "$((SECONDS - started))"
  done
}

# Parallel module batches are bounded independently of the number of selectors.
# CI isolates each module; local selections are serial unless explicitly overridden.
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
