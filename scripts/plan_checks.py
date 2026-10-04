#!/usr/bin/env python3
"""Select changed modules and their consumers from a public import graph."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

MODULE_NAME = re.compile(r"[a-z][a-z0-9-]{0,62}")
DOCUMENTATION_FILES = frozenset({"LICENSE", "scripts/build_docs.py"})


def git(*arguments: str, root: Path | None = None) -> bytes:
    result = subprocess.run(
        ["git", "--no-optional-locks", *arguments],
        cwd=root,
        capture_output=True,
        check=False,
        timeout=30,
    )
    if result.returncode:
        message = result.stderr.decode(errors="replace").strip()
        raise ValueError(message or f"git exited with status {result.returncode}")
    return result.stdout


def catalog_names(root: Path) -> set[str]:
    """Discover directories without reading metadata or module implementation."""
    catalog = root / "catalog"
    if catalog.is_symlink() or not catalog.is_dir():
        raise ValueError("catalog must be a regular directory")
    names = set()
    for directory in catalog.iterdir():
        name = directory.name
        if name == "_shared":
            continue
        if not directory.is_dir() and not directory.is_symlink():
            continue
        # Keep matrix values safe; contract validation belongs to checks/catalog.nix.
        if directory.is_symlink() or MODULE_NAME.fullmatch(name) is None:
            raise ValueError(f"invalid catalog module directory: {name}")
        names.add(name)
    if not names:
        raise ValueError("catalog must contain at least one module")
    return names


def documentation_path(path: str, status: str) -> bool:
    """Skip known documentation, not Markdown used as a private runtime fixture."""
    parts = path.split("/")
    if path in DOCUMENTATION_FILES or parts[0] in {"docs", "guides"}:
        return True
    if len(parts) == 1 and Path(path).suffix.lower() in {".md", ".rst"}:
        return True
    if len(parts) == 3 and parts[0] == "catalog" and parts[2] == "README.md":
        # Adding, removing or changing the file type can break module structure.
        return status == "M"
    return path in {"checks/README.md", "scripts/README.md"}


def validate_dependencies(value: object, names: set[str]) -> dict[str, set[str]]:
    """Consume a complete graph exported from evaluated public entry points."""
    if not isinstance(value, dict) or set(value) != names:
        raise ValueError("dependency map must cover every current catalog module")
    graph = {}
    for name, providers in value.items():
        if (
            not isinstance(providers, list)
            or any(
                not isinstance(provider, str) or provider not in names
                for provider in providers
            )
            or len(providers) != len(set(providers))
        ):
            raise ValueError(f"invalid public dependencies: {name}")
        graph[name] = set(providers)
    return graph


def dependents(graph: dict[str, set[str]], changed: set[str]) -> set[str]:
    selected = set(changed)
    while True:
        consumers = {name for name, providers in graph.items() if providers & selected}
        if consumers <= selected:
            return selected
        selected.update(consumers)


def changed_paths(root: Path, base: str, head: str) -> dict[str, str]:
    output = git(
        "diff", "--name-status", "--no-renames", "-z", base, head, "--", root=root
    )
    fields = output.split(b"\0")
    if fields.pop() != b"" or len(fields) % 2:
        raise ValueError("incomplete Git name-status output")
    return {
        os.fsdecode(path): status.decode("ascii")
        for status, path in zip(fields[::2], fields[1::2])
    }


def plan(root: Path, paths: dict[str, str] | None, dependencies: object = None) -> dict:
    names = catalog_names(root)
    graph = None if dependencies is None else validate_dependencies(dependencies, names)
    shared_paths = []
    if paths is None:
        selected = names
        shared = True
        docs_only = False
    else:
        source_paths = [
            path
            for path, status in paths.items()
            if not documentation_path(path, status)
        ]
        changed = set()
        for path in source_paths:
            parts = path.split("/")
            if len(parts) >= 3 and parts[0] == "catalog" and parts[1] != "_shared":
                changed.add(parts[1])
            else:
                # Shared/platform/harness/unknown repository source affects all pods.
                shared_paths.append(path)
        shared_paths = sorted(set(shared_paths))
        shared = bool(shared_paths)
        if shared or (changed and (graph is None or not changed <= names)):
            # Missing graph or removed pods: preserve consumers without inspecting code.
            selected = names
        elif changed:
            selected = dependents(graph, changed)
        else:
            selected = set()
        docs_only = bool(paths) and not source_paths
    modules = sorted(selected)
    return {
        "modules": modules,
        "chunks": [{"id": name, "modules": name} for name in modules],
        "shared": shared,
        "docs_only": docs_only,
        "shared_paths": shared_paths,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--all",
        action="store_true",
        help="Select every current module and shared checks",
    )
    parser.add_argument("--base", help="Base Git commit or revision")
    parser.add_argument("--head", help="Head Git commit or revision")
    parser.add_argument(
        "--dependencies",
        type=Path,
        help="JSON public-import dependency map exported for this checkout",
    )
    args = parser.parse_args(argv)
    if args.all:
        if args.base is not None or args.head is not None:
            parser.error("--all cannot be combined with --base or --head")
    elif args.base is None or args.head is None:
        parser.error("specify --all, or both --base and --head")
    for revision in (args.base, args.head):
        if revision is not None and revision.startswith("-"):
            parser.error("Git revisions must not start with a dash")
    try:
        root = Path(os.fsdecode(git("rev-parse", "--show-toplevel")).strip())
        paths = None if args.all else changed_paths(root, args.base, args.head)
        dependencies = None
        if args.dependencies is not None:
            dependencies = json.loads(args.dependencies.read_text())
            if not isinstance(dependencies, dict):
                raise ValueError("dependency file must contain a JSON object")
        result = plan(root, paths, dependencies)
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(f"plan-checks: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("plan-checks: interrupted", file=sys.stderr)
        return 130
    print(json.dumps(result, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
