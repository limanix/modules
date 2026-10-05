#!/usr/bin/env bash
set -euo pipefail
set -f
export LC_ALL=C

parse_arguments() {
  suite=${1:?Usage: run_checks.sh module|common|shared|platform check|eval|run|vm [modules]}
  phase=${2:?Specify check, eval, run or vm}
  shift 2

  case "$suite" in
    module|common|shared|platform) ;;
    *)
      printf 'Unknown suite: %s\n' "$suite" >&2
      exit 2
      ;;
  esac
  case "$phase" in
    check|eval|run|vm) ;;
    *)
      printf 'Unknown phase: %s\n' "$phase" >&2
      exit 2
      ;;
  esac
  if test "$suite" = common && test "$phase" != check; then
    printf 'The common suite runs shared and platform eval/run together\n' >&2
    exit 2
  fi

  requested_modules=()
  local argument module_name
  for argument in "$@"; do
    for module_name in $argument; do
      if [[ ! "$module_name" =~ ^[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*$ ]] || ((${#module_name} > 63)); then
        printf 'Invalid module name: %s\n' "$module_name" >&2
        exit 2
      fi
      case "$module_name" in
        internal|capabilities|pins)
          printf 'Reserved module name: %s\n' "$module_name" >&2
          exit 2
          ;;
      esac
      requested_modules+=("$module_name")
    done
  done
  if test "$suite" != module && ((${#requested_modules[@]})); then
    printf 'Only the module suite accepts module names\n' >&2
    exit 2
  fi
}

validate_build_limits() {
  max_jobs=${NIX_CHECK_JOBS:-1}
  build_cores=${NIX_BUILD_CORES:-0}
  if [[ ! "$max_jobs" =~ ^[1-9][0-9]?$ ]] || ((max_jobs > 64)); then
    printf 'NIX_CHECK_JOBS must be between 1 and 64\n' >&2
    exit 2
  fi
  if [[ ! "$build_cores" =~ ^(0|[1-9][0-9]?)$ ]] || ((build_cores > 64)); then
    printf 'NIX_BUILD_CORES must be between 0 and 64\n' >&2
    exit 2
  fi
}

require_runner_tools() {
  local tool
  for tool in nix nix-store; do
    if ! command -v "$tool" >/dev/null; then
      printf 'Required runner tool missing: %s\n' "$tool" >&2
      exit 2
    fi
  done
}

cleanup() {
  local exit_status=$?
  local result_status
  trap - EXIT
  if test "$exit_status" = 0; then
    result_status=pass
  else
    result_status=fail
  fi
  printf 'RESULT suite=%s phase=%s status=%s exit=%s seconds=%s\n' \
    "$suite" "$phase" "$result_status" "$exit_status" "$((SECONDS - started_at))"
  rm -rf "$temporary_directory"
}

initialize_runner() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.."
  runner_path="$PWD/scripts/run_checks.sh"
  started_at=$SECONDS
  temporary_directory=$(mktemp -d)
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
}

run_combined_checks() {
  local component
  if test "$suite" = common; then
    for component in shared platform; do
      bash "$runner_path" "$component" eval
      bash "$runner_path" "$component" run
    done
  else
    bash "$runner_path" "$suite" eval "${requested_modules[@]}"
    bash "$runner_path" "$suite" run "${requested_modules[@]}"
  fi
}

configure_build_cache() {
  cache_hook=''
  local cache_uri
  if test -n "${NIX_BUILD_CACHE:-}"; then
    case "$NIX_BUILD_CACHE" in
      /*) ;;
      *)
        printf 'NIX_BUILD_CACHE must be absolute\n' >&2
        exit 2
        ;;
    esac

    cache_uri=${NIX_BUILD_CACHE//\%/%25}
    cache_uri=${cache_uri// /%20}
    cache_uri=${cache_uri//\#/%23}
    cache_uri=${cache_uri//\?/%3F}
    cache_uri=${cache_uri//\&/%26}
    cache_uri=${cache_uri//+/%2B}

    if mkdir -p "$NIX_BUILD_CACHE"; then
      if test -n "${NIX_BUILD_CACHE_HOOK:-}"; then
        case "$NIX_BUILD_CACHE_HOOK" in
          /*) ;;
          *)
            printf 'NIX_BUILD_CACHE_HOOK must be absolute\n' >&2
            exit 2
            ;;
        esac
        if ! test -x "$NIX_BUILD_CACHE_HOOK"; then
          printf 'NIX_BUILD_CACHE_HOOK must be executable\n' >&2
          exit 2
        fi
        cache_hook=$'\n'"post-build-hook = $NIX_BUILD_CACHE_HOOK"
      fi
      export NIX_CONFIG="${NIX_CONFIG:-}
extra-substituters = file://$cache_uri?trusted=1$cache_hook"
    else
      printf 'Optional cache unavailable; continuing without it\n' >&2
    fi
  elif test -n "${NIX_BUILD_CACHE_HOOK:-}"; then
    printf 'NIX_BUILD_CACHE_HOOK requires NIX_BUILD_CACHE\n' >&2
    exit 2
  fi
}

initialize_evaluator() {
  nix_flags=(--extra-experimental-features nix-command --option allow-import-from-derivation false --log-format raw)
  system=$(nix eval "${nix_flags[@]}" --raw --impure --expr builtins.currentSystem)
  case "$system" in
    x86_64-linux|aarch64-linux) ;;
    *)
      printf 'A native Linux runner is required: %s\n' "$system" >&2
      exit 2
      ;;
  esac

  export LMX_CHECK_SUITE=$suite LMX_CHECK_MODULES='[]'
  if ((${#requested_modules[@]})); then
    local separator='' module_name
    LMX_CHECK_MODULES='['
    for module_name in "${requested_modules[@]}"; do
      LMX_CHECK_MODULES+="$separator\"$module_name\""
      separator=,
    done
    LMX_CHECK_MODULES+=']'
  fi
  checks_expression='let checks = import ./checks/modules.nix {
  suite = builtins.getEnv "LMX_CHECK_SUITE";
  modules = builtins.getEnv "LMX_CHECK_MODULES";
}; in builtins.getAttr (builtins.getEnv "LMX_CHECK_ATTRIBUTE") checks'
}

evaluate_attribute() {
  export LMX_CHECK_ATTRIBUTE=$1
  shift
  nix eval "${nix_flags[@]}" --impure --expr "$checks_expression" "$@"
}

run_selected_modules() {
  evaluate_attribute selectionManifest --write-to "$temporary_directory/selection"
  local module_name exit_status first_failure=0
  while IFS= read -r module_name; do
    test -n "$module_name" || continue
    exit_status=0
    bash "$runner_path" module "$phase" "$module_name" || exit_status=$?
    if test "$first_failure" = 0 && test "$exit_status" != 0; then
      first_failure=$exit_status
    fi
  done < "$temporary_directory/selection/modules"
  return "$first_failure"
}

read_primary_error() {
  local line diagnostic='' seen_error=0
  local error_pattern='^[[:space:]]*error:'
  local source_pattern='^[[:space:]]*([0-9]+[[:space:]]*)?[|]'
  local location_pattern='^[[:space:]]*at .*:[0-9]+:[0-9]+:$'
  while IFS= read -r line || test -n "$line"; do
    if [[ "$line" =~ $error_pattern ]]; then
      diagnostic=''
      seen_error=1
    fi
    if [[ "$line" =~ $source_pattern || "$line" =~ $location_pattern ]]; then
      continue
    fi
    if test "$seen_error" = 1; then
      diagnostic+="$line"$'\n'
    fi
  done < "$1"
  printf '%s' "$diagnostic"
}

run_evaluation_checks() {
  evaluate_attribute evalManifest --write-to "$manifest_directory"
  cat "$manifest_directory/results.json"
  printf '\n'

  local target case_name case_started_at exit_status expected_message diagnostic
  while IFS=$'\t' read -r target case_name; do
    test -n "$target" || continue
    export LMX_CHECK_TARGET=$target LMX_CHECK_CASE=$case_name
    case_started_at=$SECONDS
    exit_status=0
    evaluate_attribute failure --json > "$temporary_directory/failure.out" \
      2> "$temporary_directory/failure.err" || exit_status=$?

    expected_message=$(cat "$manifest_directory/expected/$target/$case_name"; printf '.')
    expected_message=${expected_message%.}
    diagnostic=$(read_primary_error "$temporary_directory/failure.err"; printf '.')
    diagnostic=${diagnostic%.}
    if test "$exit_status" != 1 || [[ "$diagnostic" != *"$expected_message"* ]]; then
      cat "$temporary_directory/failure.err" >&2
      printf 'Unexpected failure target=%s case=%s exit=%s\n' "$target" "$case_name" "$exit_status" >&2
      exit 1
    fi
    printf 'PASS target=%s fails.%s seconds=%s\n' \
      "$target" "$case_name" "$((SECONDS - case_started_at))"
  done < "$manifest_directory/failures"
}

parse_build_plan() {
  local plan_file=$1 planned_file=$2
  local line header_seen=0 expected_count=0 in_build_section=0 parsed_count=0
  local plural_pattern='^these ([1-9][0-9]*) derivations will be built:$'
  local path_pattern='^[[:space:]]+(/nix/store/[^[:space:]]+[.]drv)$'
  local any_path_pattern='/nix/store/[^[:space:]]+[.]drv'
  : > "$planned_file"

  while IFS= read -r line || test -n "$line"; do
    if test "$line" = 'this derivation will be built:'; then
      if test "$header_seen" != 0; then
        printf 'Duplicate build-plan header\n' >&2
        exit 1
      fi
      header_seen=1
      expected_count=1
      in_build_section=1
      continue
    fi
    if [[ "$line" =~ $plural_pattern ]]; then
      if test "$header_seen" != 0; then
        printf 'Duplicate build-plan header\n' >&2
        exit 1
      fi
      header_seen=1
      expected_count=${BASH_REMATCH[1]}
      in_build_section=1
      continue
    fi
    if [[ "$line" = *'will be built'* ]]; then
      printf 'Unknown build-plan header\n' >&2
      exit 1
    fi
    if test "$in_build_section" = 1 && [[ "$line" =~ $path_pattern ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}" >> "$planned_file"
      parsed_count=$((parsed_count + 1))
      continue
    fi
    in_build_section=0
    if [[ "$line" =~ $any_path_pattern ]]; then
      printf 'Unclassified planned derivation\n' >&2
      exit 1
    fi
  done < "$plan_file"

  if test "$parsed_count" != "$expected_count"; then
    printf 'Build-plan count mismatch\n' >&2
    exit 1
  fi
}

validate_local_builds() {
  local exit_status=0 path
  nix-store --realise --dry-run --option fallback false "${test_derivations[@]}" \
    > "$temporary_directory/plan.out" 2> "$temporary_directory/plan.err" || exit_status=$?
  cat "$temporary_directory/plan.err" >&2
  if test "$exit_status" != 0; then
    exit "$exit_status"
  fi

  parse_build_plan "$temporary_directory/plan.err" "$temporary_directory/planned"
  local planned_derivations=()
  while IFS= read -r path; do
    test -z "$path" || planned_derivations+=("$path")
  done < "$temporary_directory/planned"
  if ((${#planned_derivations[@]})); then
    nix derivation show "${nix_flags[@]}" "${planned_derivations[@]}" > "$temporary_directory/derivations.json"
  else
    printf '{}\n' > "$temporary_directory/derivations.json"
  fi

  export LMX_PLAN_DIRECTORY=$temporary_directory
  local build_policy_expression='let
    directory = builtins.getEnv "LMX_PLAN_DIRECTORY";
    list = name: builtins.filter builtins.isString (builtins.split "\n" (builtins.readFile (directory + "/" + name)));
    paths = name: builtins.filter (value: value != "") (list name);
    result = import ./checks/build-plan.nix {
      planned = paths "planned"; roots = paths "manifest/roots"; builds = paths "manifest/builds";
      derivations = builtins.fromJSON (builtins.readFile (directory + "/derivations.json"));
    };
  in if result.allowed then builtins.toJSON result
  else throw ("Undeclared local builds:\n" + builtins.concatStringsSep "\n" result.blocked)'
  nix eval "${nix_flags[@]}" --raw --impure --expr "$build_policy_expression"
  printf '\n'
}

realise_test_derivations() {
  local build_options=(--max-jobs "$max_jobs" --cores "$build_cores" --option fallback false --option builders "")
  if test "$(id -u)" = 0; then
    local build_users_group
    build_users_group=$(nix config show "${nix_flags[@]}" build-users-group)
    if test -z "$build_users_group"; then
      build_options+=(--option build-users-group nixbld)
    fi
  fi

  local build_started_at=$SECONDS
  nix-store --realise "${build_options[@]}" "${test_derivations[@]}"
  printf 'PASS phase=%s roots=%s seconds=%s\n' \
    "$phase" "${#test_derivations[@]}" "$((SECONDS - build_started_at))"
}

record_live_cache_paths() {
  local path build_closure=()
  if nix-store --query --requisites "${test_derivations[@]}" > "$temporary_directory/requisites"; then
    while IFS= read -r path; do
      [[ "$path" != *.drv ]] || build_closure+=("$path")
    done < "$temporary_directory/requisites"
  fi
  if ((${#build_closure[@]} == 0)) || ! cat "$temporary_directory/requisites" >> "$live_cache_file" ||
     ! nix-store --query --outputs "${build_closure[@]}" >> "$live_cache_file"; then
    printf 'Could not list live cache paths; the cache will not be pruned\n' >&2
    printf '*\n' >> "$live_cache_file"
  fi
}

run_execution_checks() {
  evaluate_attribute "${phase}Manifest" --write-to "$manifest_directory"
  test_derivations=()
  local path
  while IFS= read -r path; do
    test -z "$path" || test_derivations+=("$path")
  done < "$manifest_directory/roots"

  live_cache_file=''
  if test -n "$cache_hook" && test "$phase" = run; then
    live_cache_file=$NIX_BUILD_CACHE/.live
    : >> "$live_cache_file"
  fi
  if ((${#test_derivations[@]} == 0)); then
    printf 'No %s exports in this selection\n' "$phase"
    return 0
  fi

  if test "$phase" = vm; then
    if ! test -r /dev/kvm || ! test -w /dev/kvm; then
      printf 'VM checks require readable/writable /dev/kvm\n' >&2
      exit 2
    fi
  else
    validate_local_builds
  fi
  realise_test_derivations
  if test -n "$live_cache_file"; then
    record_live_cache_paths
  fi
}

main() {
  parse_arguments "$@"
  validate_build_limits
  require_runner_tools
  initialize_runner

  if test "$phase" = check && { test "$suite" != module || ((${#requested_modules[@]} == 1)); }; then
    run_combined_checks
    return
  fi

  configure_build_cache
  initialize_evaluator

  if test "$suite" = module && ((${#requested_modules[@]} != 1)); then
    run_selected_modules
    return
  fi

  printf 'Checking suite=%s phase=%s system=%s cache=%s\n' \
    "$suite" "$phase" "$system" "${NIX_BUILD_CACHE:-configured Nix substituters}"
  manifest_directory="$temporary_directory/manifest"
  case "$phase" in
    eval) run_evaluation_checks ;;
    run|vm) run_execution_checks ;;
  esac
}

main "$@"
