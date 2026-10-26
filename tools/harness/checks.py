"""Run catalog checks through Nix and report their results.

The check command selects module, shared, or platform checks.
The common suite runs the shared and platform checks together.
checks/modules.nix supplies the checks for the selected Linux system.

The phases are:
- eval: check configuration values and expected error messages.
- run: ask Nix to build the selected test results or reuse them from a cache.
- check: run both phases.

Before a build, the runner checks which local builds are allowed.
It also sets build limits, connects the cache, and records paths to keep.
Each run reports its result, exit code, and time spent.
"""

import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from types import FrameType
from typing import Any, TextIO

from harness import nix
from harness.cache import LIVE_FILE, encode_uri

SUITES = ("module", "common", "shared", "platform")
PHASES = ("check", "eval", "run")
USAGE = "Usage: harness check module|common|shared|platform check|eval|run [modules]"
MODULE_NAME = re.compile(r"^[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*$")
RESERVED = ("internal", "capabilities", "pins")
MODULES_FILE = "checks/modules.nix"
BUILD_PLAN_FILE = "checks/build-plan.nix"


class UsageError(Exception):
    pass


class CheckFailure(Exception):
    def __init__(self, status: int) -> None:
        super().__init__(f"check failed with status {status}")
        self.status = status


class Interrupted(Exception):
    def __init__(self, status: int) -> None:
        super().__init__(f"interrupted with status {status}")
        self.status = status


@dataclass(frozen=True)
class Request:
    suite: str
    phase: str
    modules: tuple[str, ...]


@dataclass(frozen=True)
class Limits:
    max_jobs: int
    cores: int


def parse_request(arguments: Sequence[str]) -> Request:
    if len(arguments) < 2:
        raise UsageError(USAGE)
    suite, phase, *rest = arguments
    if suite not in SUITES:
        raise UsageError(f"Unknown suite: {suite}")
    if phase not in PHASES:
        raise UsageError(f"Unknown phase: {phase}")
    if suite == "common" and phase != "check":
        raise UsageError("The common suite runs shared and platform eval/run together")
    modules: list[str] = []
    for argument in rest:
        for name in argument.split():
            if not MODULE_NAME.match(name) or len(name) > 63:
                raise UsageError(f"Invalid module name: {name}")
            if name in RESERVED:
                raise UsageError(f"Reserved module name: {name}")
            modules.append(name)
    if suite != "module" and modules:
        raise UsageError("Only the module suite accepts module names")
    return Request(suite, phase, tuple(modules))


def build_limits(environment: Mapping[str, str]) -> Limits:
    max_jobs = environment.get("NIX_CHECK_JOBS", "1")
    cores = environment.get("NIX_BUILD_CORES", "0")
    if not re.fullmatch(r"[1-9][0-9]?", max_jobs) or int(max_jobs) > 64:
        raise UsageError("NIX_CHECK_JOBS must be between 1 and 64")
    if not re.fullmatch(r"0|[1-9][0-9]?", cores) or int(cores) > 64:
        raise UsageError("NIX_BUILD_CORES must be between 0 and 64")
    return Limits(int(max_jobs), int(cores))


def require_tools() -> None:
    for tool in ("nix", "nix-store"):
        if shutil.which(tool) is None:
            raise UsageError(f"Required runner tool missing: {tool}")


def seconds_since(started: float) -> int:
    return int(time.monotonic() - started)


class Runner:
    def __init__(
        self,
        request: Request,
        limits: Limits,
        environment: Mapping[str, str],
        out: TextIO = sys.stdout,
        err: TextIO = sys.stderr,
    ) -> None:
        self.request = request
        self.limits = limits
        self.environment = dict(environment)
        self.out = out
        self.err = err
        self.cache_directory = ""
        self.cache_hook = ""
        self.system = ""

    def run(self) -> int:
        started = time.monotonic()
        status = 1
        try:
            self.execute()
            status = 0
        except UsageError as error:
            print(error, file=self.err)
            status = 2
        except CheckFailure as failure:
            status = failure.status
        except KeyboardInterrupt:
            status = 130
        except Interrupted as interrupted:
            status = interrupted.status
        finally:
            outcome = "pass" if status == 0 else "fail"
            print(
                f"RESULT suite={self.request.suite} phase={self.request.phase} "
                f"status={outcome} exit={status} seconds={seconds_since(started)}",
                file=self.out,
                flush=True,
            )
        return status

    def child(self, request: Request) -> int:
        return Runner(request, self.limits, self.environment, self.out, self.err).run()

    def execute(self) -> None:
        if self.request.suite == "common":
            for component in ("shared", "platform"):
                status = self.child(Request(component, "check", ()))
                if status != 0:
                    raise CheckFailure(status)
            return
        self.configure_cache()
        self.system = nix.current_system()
        if self.system not in nix.SYSTEMS:
            raise UsageError(f"A native Linux runner is required: {self.system}")
        if self.request.suite == "module" and len(self.request.modules) != 1:
            self.run_selected_modules()
            return
        cache = self.cache_directory or "configured Nix substituters"
        print(
            f"Checking suite={self.request.suite} phase={self.request.phase} "
            f"system={self.system} cache={cache}",
            file=self.out,
            flush=True,
        )
        phase = self.request.phase
        if phase == "check":
            manifest = self.evaluate_json("checkManifest")
            self.evaluation_stage(manifest["eval"])
            self.execution_stage("run", manifest["run"])
        elif phase == "eval":
            self.evaluation_stage(self.evaluate_json("evalManifest"))
        else:
            self.execution_stage(phase, self.evaluate_json(f"{phase}Manifest"))

    def configure_cache(self) -> None:
        cache = self.environment.get("NIX_BUILD_CACHE", "")
        hook = self.environment.get("NIX_BUILD_CACHE_HOOK", "")
        if not cache:
            if hook:
                raise UsageError("NIX_BUILD_CACHE_HOOK requires NIX_BUILD_CACHE")
            return
        if not cache.startswith("/"):
            raise UsageError("NIX_BUILD_CACHE must be absolute")
        self.cache_directory = cache
        try:
            Path(cache).mkdir(parents=True, exist_ok=True)
        except OSError:
            print("Optional cache unavailable; continuing without it", file=self.err)
            return
        hook_line = ""
        if hook:
            if not hook.startswith("/"):
                raise UsageError("NIX_BUILD_CACHE_HOOK must be absolute")
            if not os.access(hook, os.X_OK):
                raise UsageError("NIX_BUILD_CACHE_HOOK must be executable")
            self.cache_hook = hook
            hook_line = f"\npost-build-hook = {hook}"
        existing = self.environment.get("NIX_CONFIG", "")
        self.environment["NIX_CONFIG"] = (
            f"{existing}\nextra-substituters = file://{encode_uri(cache)}?trusted=1{hook_line}"
        )

    def run_selected_modules(self) -> None:
        selection = self.evaluate_raw("selectionManifest.modules")
        first_failure = 0
        for name in selection.splitlines():
            if not name:
                continue
            status = self.child(Request("module", self.request.phase, (name,)))
            if first_failure == 0 and status != 0:
                first_failure = status
        if first_failure:
            raise CheckFailure(first_failure)

    def arguments(self) -> list[str]:
        return [
            "--argstr",
            "suite",
            self.request.suite,
            "--argstr",
            "modules",
            json.dumps(list(self.request.modules)),
            "--argstr",
            "system",
            self.system,
        ]

    def evaluate(self, attribute: str, output: str, extra: Sequence[str] = ()) -> str:
        completed = subprocess.run(
            [
                "nix",
                "eval",
                *nix.FLAGS,
                "--file",
                MODULES_FILE,
                attribute,
                *self.arguments(),
                *extra,
                output,
            ],
            stdout=subprocess.PIPE,
            text=True,
            env=self.environment,
        )
        if completed.returncode != 0:
            raise CheckFailure(completed.returncode)
        return completed.stdout

    def evaluate_raw(self, attribute: str) -> str:
        return self.evaluate(attribute, "--raw")

    def evaluate_json(self, attribute: str) -> dict[str, Any]:
        return dict(json.loads(self.evaluate(attribute, "--json")))

    def evaluation_stage(self, manifest: dict[str, Any]) -> None:
        started = time.monotonic()
        print(manifest["results.json"], file=self.out)
        print(file=self.out, flush=True)
        for row in manifest["failures"].splitlines():
            if not row:
                continue
            target, case = row.split("\t", 1)
            case_started = time.monotonic()
            completed = subprocess.run(
                [
                    "nix",
                    "eval",
                    *nix.FLAGS,
                    "--file",
                    MODULES_FILE,
                    "failure",
                    *self.arguments(),
                    "--argstr",
                    "target",
                    target,
                    "--argstr",
                    "case",
                    case,
                    "--json",
                ],
                capture_output=True,
                text=True,
                env=self.environment,
            )
            expected = manifest["expected"][target][case]
            diagnostic = nix.primary_error(completed.stderr)
            if completed.returncode != 1 or expected not in diagnostic:
                self.err.write(completed.stderr)
                print(
                    f"Unexpected failure target={target} case={case} exit={completed.returncode}",
                    file=self.err,
                )
                raise CheckFailure(1)
            print(
                f"PASS target={target} fails.{case} seconds={seconds_since(case_started)}",
                file=self.out,
                flush=True,
            )
        print(f"PASS phase=eval seconds={seconds_since(started)}", file=self.out, flush=True)

    def execution_stage(self, stage: str, manifest: dict[str, Any]) -> None:
        roots = [path for path in manifest["roots"].splitlines() if path]
        builds = [path for path in manifest["builds"].splitlines() if path]
        live_file: Path | None = None
        if self.cache_hook:
            live_file = Path(self.cache_directory) / LIVE_FILE
            live_file.touch()
        if not roots:
            print(f"No {stage} exports in this selection", file=self.out, flush=True)
            return
        self.validate_local_builds(roots, builds)
        self.realise(stage, roots)
        if live_file is not None:
            self.record_live_paths(roots, live_file)

    def validate_local_builds(self, roots: list[str], builds: list[str]) -> None:
        completed = subprocess.run(
            ["nix-store", "--realise", "--dry-run", "--option", "fallback", "false", *roots],
            capture_output=True,
            text=True,
            env=self.environment,
        )
        self.err.write(completed.stderr)
        self.err.flush()
        if completed.returncode != 0:
            raise CheckFailure(completed.returncode)
        try:
            planned = nix.parse_build_plan(completed.stderr)
        except nix.PlanError as error:
            print(error, file=self.err)
            raise CheckFailure(1) from error
        derivations = "{}\n"
        if planned:
            shown = subprocess.run(
                ["nix", "derivation", "show", *nix.FLAGS, *planned],
                stdout=subprocess.PIPE,
                text=True,
                env=self.environment,
            )
            if shown.returncode != 0:
                raise CheckFailure(shown.returncode)
            derivations = shown.stdout
        with tempfile.TemporaryDirectory() as directory:
            metadata = Path(directory) / "derivations.json"
            metadata.write_text(derivations)
            expression = (
                f"let result = import ./{BUILD_PLAN_FILE} {{"
                f" planned = {nix.list_literal(planned)};"
                f" roots = {nix.list_literal(roots)};"
                f" builds = {nix.list_literal(builds)};"
                " derivations = builtins.fromJSON"
                f" (builtins.readFile {nix.path_literal(metadata)});"
                " }; in if result.allowed then builtins.toJSON result"
                ' else throw ("Undeclared local builds:\\n"'
                ' + builtins.concatStringsSep "\\n" result.blocked)'
            )
            policy = subprocess.run(
                ["nix", "eval", *nix.FLAGS, "--raw", "--impure", "--expr", expression],
                stdout=subprocess.PIPE,
                text=True,
                env=self.environment,
            )
        if policy.returncode != 0:
            raise CheckFailure(policy.returncode)
        print(policy.stdout, file=self.out, flush=True)

    def realise(self, stage: str, roots: list[str]) -> None:
        options = [
            "--max-jobs",
            str(self.limits.max_jobs),
            "--cores",
            str(self.limits.cores),
            "--option",
            "fallback",
            "false",
            "--option",
            "builders",
            "",
        ]
        if os.getuid() == 0:
            group = subprocess.run(
                ["nix", "config", "show", *nix.FLAGS, "build-users-group"],
                stdout=subprocess.PIPE,
                text=True,
                env=self.environment,
            )
            if group.stdout.strip() == "":
                options += ["--option", "build-users-group", "nixbld"]
        started = time.monotonic()
        completed = subprocess.run(
            ["nix-store", "--realise", *options, *roots], env=self.environment
        )
        if completed.returncode != 0:
            raise CheckFailure(completed.returncode)
        print(
            f"PASS phase={stage} roots={len(roots)} seconds={seconds_since(started)}",
            file=self.out,
            flush=True,
        )

    def record_live_paths(self, roots: list[str], live_file: Path) -> None:
        requisites = subprocess.run(
            ["nix-store", "--query", "--requisites", *roots],
            stdout=subprocess.PIPE,
            text=True,
            env=self.environment,
        )
        closure = (
            [path for path in requisites.stdout.splitlines() if path.endswith(".drv")]
            if requisites.returncode == 0
            else []
        )
        listed = False
        if closure:
            outputs = subprocess.run(
                ["nix-store", "--query", "--outputs", *closure],
                stdout=subprocess.PIPE,
                text=True,
                env=self.environment,
            )
            if outputs.returncode == 0:
                with live_file.open("a") as live:
                    live.write(requisites.stdout)
                    live.write(outputs.stdout)
                listed = True
        if not listed:
            print("Could not list live cache paths; the cache will not be pruned", file=self.err)
            with live_file.open("a") as live:
                live.write("*\n")


def interrupt(status: int) -> None:
    def handler(_signal: int, _frame: FrameType | None) -> None:
        raise Interrupted(status)

    signal.signal(signal.SIGTERM if status == 143 else signal.SIGINT, handler)


def check(arguments: Sequence[str], environment: Mapping[str, str] = os.environ) -> int:
    try:
        request = parse_request(arguments)
        limits = build_limits(environment)
        require_tools()
        nix.require_supported_version(nix.version())
    except (UsageError, nix.VersionError) as error:
        print(error, file=sys.stderr)
        return 2
    interrupt(143)
    return Runner(request, limits, environment).run()
