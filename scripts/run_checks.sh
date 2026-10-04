#!/usr/bin/env bash
# Stage scheduling belongs here; application behavior belongs in public test.nix.
set -euo pipefail
set -f
export LC_ALL=C

# Only the outer call owns the process-group timeout. Its children use this
# positional entry, rather than an inherited environment flag.
execute=0
if test "${1:-}" = --execute; then execute=1; shift; fi
suite=${1:?Usage: run_checks.sh module|common|shared|platform check|eval|run|vm [modules]}
phase=${2:?Specify check, eval, run or vm}
shift 2
case "$suite" in module|common|shared|platform) ;; *) printf 'Unknown suite: %s\n' "$suite" >&2; exit 2 ;; esac
case "$phase" in check|eval|run|vm) ;; *) printf 'Unknown phase: %s\n' "$phase" >&2; exit 2 ;; esac
if test "$suite" = common && test "$phase" != check; then
  printf 'The common suite runs shared and platform eval/run together\n' >&2; exit 2
fi
requested=()
for argument in "$@"; do
  for name in $argument; do
    if [[ ! "$name" =~ ^[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*$ ]] || ((${#name} > 63)); then
      printf 'Invalid module name: %s\n' "$name" >&2; exit 2
    fi
    case "$name" in internal|capabilities|pins) printf 'Reserved module name: %s\n' "$name" >&2; exit 2 ;; esac
    requested+=("$name")
  done
done
if test "$suite" != module && ((${#requested[@]})); then
  printf 'Only the module suite accepts module names\n' >&2; exit 2
fi
limit=${NIX_CHECK_TIMEOUT:-540}
if test "$phase" = vm; then limit=${NIX_CHECK_TIMEOUT:-900}; fi
case_limit=${NIX_CHECK_CASE_TIMEOUT:-$limit}
build_limit=${NIX_BUILD_TIMEOUT:-$limit}
jobs=${NIX_CHECK_JOBS:-1}
cores=${NIX_BUILD_CORES:-0}
for value in "$limit" "$case_limit" "$build_limit" "$jobs"; do
  if [[ ! "$value" =~ ^[1-9][0-9]*$ ]] || ((${#value} > 6)); then
    printf 'Timeouts and build jobs must be bounded positive integers\n' >&2; exit 2
  fi
done
if test -z "${NIX_CHECK_CASE_TIMEOUT:-}" && ((case_limit > 180)); then case_limit=180; fi
if [[ ! "$cores" =~ ^(0|[1-9][0-9]*)$ ]] || ((${#cores} > 6)); then
  printf 'Build cores must be zero or a bounded positive integer\n' >&2; exit 2
fi
maximum=540
if test "$phase" = vm; then maximum=900; fi
if ((limit > maximum || case_limit > limit || build_limit > limit || jobs > 64 || cores > 64)); then
  printf 'Check limits exceed the per-module budget (%ss)\n' "$maximum" >&2; exit 2
fi
for tool in timeout nix nix-store; do
  command -v "$tool" >/dev/null || { printf 'Required runner tool missing: %s\n' "$tool" >&2; exit 2; }
done
# Discovery has its own case deadline. Every selected module gets a fresh
# whole-cycle deadline; a slow module cannot consume another module's budget.
if test "$execute" = 0 && { test "$suite" != module || ((${#requested[@]} == 1)); }; then
  if ((${#requested[@]})); then
    exec timeout --kill-after=10s "$limit" bash "$0" --execute "$suite" "$phase" "${requested[@]}"
  fi
  exec timeout --kill-after=10s "$limit" bash "$0" --execute "$suite" "$phase"
fi
cd "$(dirname "${BASH_SOURCE[0]}")/.."
started=$SECONDS
temporary=$(mktemp -d)
cleanup() {
  status=$?
  trap - EXIT
  printf 'RESULT suite=%s phase=%s status=%s exit=%s seconds=%s\n' "$suite" "$phase" "$([ "$status" = 0 ] && printf pass || printf fail)" "$status" "$((SECONDS - started))"
  rm -rf "$temporary"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if test "$phase" = check && { test "$suite" != module || ((${#requested[@]} == 1)); }; then
  if test "$suite" = common; then
    for component in shared platform; do
      bash "$PWD/scripts/run_checks.sh" --execute "$component" eval
      bash "$PWD/scripts/run_checks.sh" --execute "$component" run
    done
  elif ((${#requested[@]})); then
    bash "$PWD/scripts/run_checks.sh" --execute "$suite" eval "${requested[@]}"
    bash "$PWD/scripts/run_checks.sh" --execute "$suite" run "${requested[@]}"
  else
    bash "$PWD/scripts/run_checks.sh" --execute "$suite" eval
    bash "$PWD/scripts/run_checks.sh" --execute "$suite" run
  fi
  exit 0
fi

# File caches remain optional and never grant local build permissions.
if test -n "${NIX_BUILD_CACHE:-}"; then
  case "$NIX_BUILD_CACHE" in /*) ;; *) printf 'NIX_BUILD_CACHE must be absolute\n' >&2; exit 2 ;; esac
  uri=${NIX_BUILD_CACHE//\%/%25}; uri=${uri// /%20}; uri=${uri//\#/%23}
  uri=${uri//\?/%3F}; uri=${uri//\&/%26}; uri=${uri//+/%2B}
  if mkdir -p "$NIX_BUILD_CACHE"; then
    cache_hook=''
    if test -n "${NIX_BUILD_CACHE_HOOK:-}"; then
      case "$NIX_BUILD_CACHE_HOOK" in /*) ;; *) printf 'NIX_BUILD_CACHE_HOOK must be absolute\n' >&2; exit 2 ;; esac
      test -x "$NIX_BUILD_CACHE_HOOK" || { printf 'NIX_BUILD_CACHE_HOOK must be executable\n' >&2; exit 2; }
      cache_hook=$'\n'"post-build-hook = $NIX_BUILD_CACHE_HOOK"
    fi
    export NIX_CONFIG="${NIX_CONFIG:-}
extra-substituters = file://$uri?trusted=1$cache_hook"
  else
    printf 'Optional cache unavailable; continuing without it\n' >&2
  fi
elif test -n "${NIX_BUILD_CACHE_HOOK:-}"; then
  printf 'NIX_BUILD_CACHE_HOOK requires NIX_BUILD_CACHE\n' >&2; exit 2
fi
flags=(--extra-experimental-features nix-command --option allow-import-from-derivation false --log-format raw)
system=$(timeout --foreground --kill-after=10s "$case_limit" nix eval "${flags[@]}" --raw --impure --expr builtins.currentSystem)
case "$system" in x86_64-linux|aarch64-linux) ;; *) printf 'A native Linux runner is required: %s\n' "$system" >&2; exit 2 ;; esac
export LMX_CHECK_SUITE=$suite LMX_CHECK_MODULES='[]'
if ((${#requested[@]})); then
  separator=''; LMX_CHECK_MODULES='['
  for name in "${requested[@]}"; do LMX_CHECK_MODULES+="$separator\"$name\""; separator=,; done
  LMX_CHECK_MODULES+=']'
fi
expression='let checks = import ./checks/modules.nix {
  suite = builtins.getEnv "LMX_CHECK_SUITE";
  modules = builtins.getEnv "LMX_CHECK_MODULES";
}; in builtins.getAttr (builtins.getEnv "LMX_CHECK_ATTRIBUTE") checks'
evaluate() {
  export LMX_CHECK_ATTRIBUTE=$1
  shift
  timeout --foreground --kill-after=10s "$case_limit" nix eval "${flags[@]}" --impure --expr "$expression" "$@"
}
primary_error() {
  # Source excerpts and trace frames are not evidence of the expected error.
  local line text='' seen=0
  local error_pattern='^[[:space:]]*error:'
  local source_pattern='^[[:space:]]*([0-9]+[[:space:]]*)?[|]'
  local location_pattern='^[[:space:]]*at .*:[0-9]+:[0-9]+:$'
  while IFS= read -r line || test -n "$line"; do
    if [[ "$line" =~ $error_pattern ]]; then text=''; seen=1; fi
    if [[ "$line" =~ $source_pattern || "$line" =~ $location_pattern ]]; then continue; fi
    if test "$seen" = 1; then text+="$line"$'\n'; fi
  done < "$1"
  printf '%s' "$text"
}

# Keep each pod in its own evaluator and independently bounded process group.
if test "$suite" = module && ((${#requested[@]} != 1)); then
  evaluate selectionManifest --write-to "$temporary/selection"
  failed=0
  while IFS= read -r name; do
    test -n "$name" || continue
    status=0
    bash "$PWD/scripts/run_checks.sh" module "$phase" "$name" || status=$?
    if test "$failed" = 0 && test "$status" != 0; then failed=$status; fi
  done < "$temporary/selection/modules"
  exit "$failed"
fi

printf 'Checking suite=%s phase=%s system=%s cache=%s\n' "$suite" "$phase" "$system" "${NIX_BUILD_CACHE:-configured Nix substituters}"

manifest="$temporary/manifest"
if test "$phase" = eval; then
  evaluate evalManifest --write-to "$manifest"
  cat "$manifest/results.json"
  printf '\n'
  while IFS=$'\t' read -r target key; do
    test -n "$target" || continue
    export LMX_CHECK_TARGET=$target LMX_CHECK_CASE=$key
    case_started=$SECONDS
    status=0
    evaluate failure --json > "$temporary/failure.out" 2> "$temporary/failure.err" || status=$?
    expected=$(cat "$manifest/expected/$target/$key"; printf '.')
    expected=${expected%.}
    diagnostic=$(primary_error "$temporary/failure.err"; printf '.')
    diagnostic=${diagnostic%.}
    if test "$status" != 1 || [[ "$diagnostic" != *"$expected"* ]]; then
      cat "$temporary/failure.err" >&2
      printf 'Unexpected failure target=%s case=%s exit=%s\n' "$target" "$key" "$status" >&2
      exit 1
    fi
    printf 'PASS target=%s fails.%s seconds=%s\n' "$target" "$key" "$((SECONDS - case_started))"
  done < "$manifest/failures"
  exit 0
fi

evaluate "${phase}Manifest" --write-to "$manifest"
derivations=()
while IFS= read -r path; do test -z "$path" || derivations+=("$path"); done < "$manifest/roots"
if ((${#derivations[@]} == 0)); then printf 'No %s exports in this selection\n' "$phase"; exit 0; fi
if test "$phase" = vm; then
  if ! test -r /dev/kvm || ! test -w /dev/kvm; then printf 'VM checks require readable/writable /dev/kvm\n' >&2; exit 2; fi
else
  status=0
  timeout --foreground --kill-after=10s "$case_limit" nix-store --realise --dry-run --option fallback false "${derivations[@]}" > "$temporary/plan.out" 2> "$temporary/plan.err" || status=$?
  cat "$temporary/plan.err" >&2
  test "$status" = 0 || exit "$status"
  # Fail closed on an unknown or count-mismatched build section.
  header=0; expected=0; section=0; count=0
  plural_pattern='^these ([1-9][0-9]*) derivations will be built:$'
  path_pattern='^[[:space:]]+(/nix/store/[^[:space:]]+[.]drv)$'
  any_path_pattern='/nix/store/[^[:space:]]+[.]drv'
  : > "$temporary/planned"
  while IFS= read -r line || test -n "$line"; do
    if test "$line" = 'this derivation will be built:'; then
      test "$header" = 0 || { printf 'Duplicate build-plan header\n' >&2; exit 1; }
      header=1; expected=1; section=1; continue
    fi
    if [[ "$line" =~ $plural_pattern ]]; then
      test "$header" = 0 || { printf 'Duplicate build-plan header\n' >&2; exit 1; }
      header=1; expected=${BASH_REMATCH[1]}; section=1; continue
    fi
    if [[ "$line" = *'will be built'* ]]; then printf 'Unknown build-plan header\n' >&2; exit 1; fi
    if test "$section" = 1 && [[ "$line" =~ $path_pattern ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}" >> "$temporary/planned"
      count=$((count + 1)); continue
    fi
    section=0
    if [[ "$line" =~ $any_path_pattern ]]; then printf 'Unclassified planned derivation\n' >&2; exit 1; fi
  done < "$temporary/plan.err"
  test "$count" = "$expected" || { printf 'Build-plan count mismatch\n' >&2; exit 1; }
  planned=()
  while IFS= read -r path; do test -z "$path" || planned+=("$path"); done < "$temporary/planned"
  if ((${#planned[@]})); then
    timeout --foreground --kill-after=10s "$case_limit" nix derivation show "${flags[@]}" "${planned[@]}" > "$temporary/derivations.json"
  else printf '{}\n' > "$temporary/derivations.json"
  fi
  export LMX_PLAN_DIRECTORY=$temporary
  policy='let
    directory = builtins.getEnv "LMX_PLAN_DIRECTORY";
    list = name: builtins.filter builtins.isString (builtins.split "\n" (builtins.readFile (directory + "/" + name)));
    paths = name: builtins.filter (value: value != "") (list name);
    result = import ./checks/build-plan.nix {
      planned = paths "planned"; roots = paths "manifest/roots"; builds = paths "manifest/builds";
      derivations = builtins.fromJSON (builtins.readFile (directory + "/derivations.json"));
    };
  in if result.allowed then builtins.toJSON result
  else throw ("Undeclared local builds:\n" + builtins.concatStringsSep "\n" result.blocked)'
  timeout --foreground --kill-after=10s "$case_limit" nix eval "${flags[@]}" --raw --impure --expr "$policy"
  printf '\n'
fi
options=(--max-jobs "$jobs" --cores "$cores" --option timeout "$build_limit" --option fallback false --option builders "")
if test "$(id -u)" = 0; then
  group=$(nix config show "${flags[@]}" build-users-group)
  test -n "$group" || options+=(--option build-users-group nixbld)
fi
build_started=$SECONDS
nix-store --realise "${options[@]}" "${derivations[@]}"
printf 'PASS phase=%s roots=%s seconds=%s\n' "$phase" "${#derivations[@]}" "$((SECONDS - build_started))"
