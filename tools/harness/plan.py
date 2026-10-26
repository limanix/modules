"""Select checks from changed paths and literal Nix references, including test sources.

This is deliberately not a Nix parser: references in comments can select extra checks.
A reference to a directory selects its descendants, including a literal prefix before
a computed version path. Removed or unknown module directories select the whole catalog.
"""

import json
import re
import subprocess
from collections.abc import Iterable
from pathlib import Path
from typing import TypedDict

from harness import REPOSITORY, graph

RELATIVE_PATH = re.compile(r"(?<![\w./-])(?:\.\.?/)+[\w./+-]*")
FULL_FILES = {"flake.nix", "flake.lock", "interface.nix"}
PLUMBING = {"Taskfile.yml", ".taskrc.yml"}
IMAGE_FILES = {
    "flake.nix",
    "flake.lock",
    "platform.nix",
    "image.nix",
    "tools/harness/__main__.py",
    "tools/harness/release.py",
    *PLUMBING,
    ".github/workflows/pr.yml",
    ".github/workflows/release.yml",
    ".github/workflows/image.yml",
}


class Plan(TypedDict):
    targets: list[str]
    image: bool


def dependencies(modules: list[Path]) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {module.name: set() for module in modules}
    for module in modules:
        for source in module.rglob("*.nix"):
            for literal in RELATIVE_PATH.findall(source.read_text()):
                reference = (source.parent / literal).resolve()
                for dependency in modules:
                    if dependency != module and (
                        reference.is_relative_to(dependency) or dependency.is_relative_to(reference)
                    ):
                        result[module.name].add(dependency.name)
    return result


def from_paths(
    changed_paths: Iterable[str], *, repository: Path = REPOSITORY, all_targets: bool = False
) -> Plan:
    repository = repository.resolve()
    kinds = graph.kinds((repository / "checks/catalog-kinds.nix").read_text())
    modules = graph.module_directories(repository / "catalog", kinds)
    owners = {module.relative_to(repository).as_posix(): module.name for module in modules}
    paths = set(changed_paths)
    selected: set[str] = set()
    full = all_targets
    for path in paths:
        if path in FULL_FILES or path.startswith(("catalog/_shared/", "checks/", "tools/")):
            full = True
        elif path in PLUMBING or path.startswith(".github/workflows/"):
            selected.add("common")
        elif path.startswith(tuple(f"catalog/{kind}/" for kind in kinds)):
            owner = owners.get("/".join(path.split("/")[:3]))
            if owner is None:
                full = True
            else:
                selected.add(owner)

    if full:
        selected = {"common", *(module.name for module in modules)}
    elif selected - {"common"}:
        imports_by_module = dependencies(modules)
        while (
            consumers := {name for name, imports in imports_by_module.items() if imports & selected}
            - selected
        ):
            selected.update(consumers)
    return {"targets": sorted(selected), "image": all_targets or bool(paths & IMAGE_FILES)}


def plan(base: str = "HEAD^1", all_targets: bool = False, repository: Path = REPOSITORY) -> Plan:
    paths: list[str] = []
    if not all_targets:
        changed = subprocess.run(
            ["git", "diff", "--name-only", "--no-renames", "-z", base, "HEAD", "--"],
            cwd=repository,
            stdout=subprocess.PIPE,
            text=True,
            check=True,
        )
        paths = [path for path in changed.stdout.split("\0") if path]
    return from_paths(paths, repository=repository, all_targets=all_targets)


def outputs(result: Plan) -> None:
    print(f"targets={json.dumps(result['targets'], separators=(',', ':'))}")
    print(f"image={str(result['image']).lower()}")
