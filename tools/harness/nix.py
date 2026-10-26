"""Provide shared helpers for calling Nix and reading its output.

This file holds common command flags and the supported Nix versions and systems.
It can read the installed Nix version and the current system name.

The check runner uses these helpers to:
- Find the main error message for an expected failure.
- Read the local builds listed by a dry run.
- Turn Python values into escaped Nix strings and lists.

An unsupported Nix version or an unknown build-plan format raises an error.
This keeps format checks and text parsing in one place.
"""

import re
import subprocess
from collections.abc import Sequence
from pathlib import Path

FLAGS = (
    "--extra-experimental-features",
    "nix-command",
    "--option",
    "allow-import-from-derivation",
    "false",
    "--log-format",
    "raw",
)
SUPPORTED_VERSIONS = ("2.35.2",)
SYSTEMS = ("aarch64-linux", "x86_64-linux")

ERROR_LINE = re.compile(r"^\s*error:")
SOURCE_LINE = re.compile(r"^\s*(\d+\s*)?\|")
LOCATION_LINE = re.compile(r"^\s*at .*:\d+:\d+:$")
SINGLE_BUILD = "this derivation will be built:"
PLURAL_BUILD = re.compile(r"^these ([1-9][0-9]*) derivations will be built:$")
PLANNED_PATH = re.compile(r"^\s+(/nix/store/\S+\.drv)$")
STORE_DERIVATION = re.compile(r"/nix/store/\S+\.drv")


class PlanError(Exception):
    pass


class VersionError(Exception):
    pass


def version(run: subprocess.CompletedProcess[str] | None = None) -> str:
    completed = run or subprocess.run(
        ["nix", "--version"], capture_output=True, text=True, check=True
    )
    return completed.stdout.split()[-1]


def require_supported_version(found: str) -> None:
    if found not in SUPPORTED_VERSIONS:
        supported = ", ".join(SUPPORTED_VERSIONS)
        raise VersionError(f"Nix {found} is not supported by the harness; it supports {supported}")


def current_system() -> str:
    completed = subprocess.run(
        ["nix", "eval", *FLAGS, "--raw", "--impure", "--expr", "builtins.currentSystem"],
        capture_output=True,
        text=True,
        check=True,
    )
    return completed.stdout


def primary_error(text: str) -> str:
    diagnostic: list[str] = []
    seen = False
    for line in text.splitlines():
        if ERROR_LINE.match(line):
            diagnostic = []
            seen = True
        if SOURCE_LINE.match(line) or LOCATION_LINE.match(line):
            continue
        if seen:
            diagnostic.append(line)
    return "".join(f"{line}\n" for line in diagnostic)


def parse_build_plan(text: str) -> list[str]:
    planned: list[str] = []
    header_seen = False
    expected = 0
    in_build_section = False
    for line in text.splitlines():
        plural = PLURAL_BUILD.match(line)
        if line == SINGLE_BUILD or plural:
            if header_seen:
                raise PlanError("Duplicate build-plan header")
            header_seen = True
            expected = int(plural.group(1)) if plural else 1
            in_build_section = True
            continue
        if "will be built" in line:
            raise PlanError("Unknown build-plan header")
        path = PLANNED_PATH.match(line)
        if in_build_section and path:
            planned.append(path.group(1))
            continue
        in_build_section = False
        if STORE_DERIVATION.search(line):
            raise PlanError("Unclassified planned derivation")
    if len(planned) != expected:
        raise PlanError("Build-plan count mismatch")
    return planned


def string_literal(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("${", "\\${")
    return f'"{escaped}"'


def list_literal(values: Sequence[str]) -> str:
    return "[ " + " ".join(string_literal(value) for value in values) + " ]"


def path_literal(path: Path) -> str:
    return string_literal(str(path))
