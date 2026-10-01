"""Select changed catalog modules and split them into CI jobs."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


CHUNK_SIZE = 4
COMMON_FILES = frozenset({
    "Taskfile.yml",
    ".taskrc.yml",
    "flake.nix",
    "flake.lock",
    "interface.nix",
    "scripts/run_checks.sh",
    "scripts/cache_nix_build.sh",
    "scripts/plan_checks.py",
})


def git(*arguments: str, root: Path | None = None) -> bytes:
    result = subprocess.run(
        ["git", *arguments], cwd=root, capture_output=True, check=False,
    )
    if result.returncode:
        message = result.stderr.decode(errors="replace").strip()
        raise ValueError(message or f"git exited with status {result.returncode}")
    return result.stdout


def catalog_names(root: Path) -> list[str]:
    return sorted(
        entry.name for entry in (root / "catalog").iterdir()
        if entry.is_dir() and entry.name != "_shared"
    )


def common_path(path: str) -> bool:
    return not readme_path(path) and (
        path in COMMON_FILES
        or path.startswith("checks/")
        or path.startswith(".github/workflows/")
        or (path.startswith("catalog/_shared/") and path.endswith(".nix"))
    )


def readme_path(path: str) -> bool:
    return path.rsplit("/", 1)[-1] == "README.md"


def changed_paths(root: Path, base: str, head: str) -> list[str]:
    output = git("diff", "--name-only", "--no-renames", "-z", base, head, "--", root=root)
    return [os.fsdecode(path) for path in output.split(b"\0") if path]


def plan(root: Path, paths: list[str] | None) -> dict:
    available = catalog_names(root)
    if paths is None:
        modules = available
        shared_paths = []
        readme_only = False
    else:
        changed = set()
        for path in paths:
            if readme_path(path):
                continue
            parts = path.split("/")
            if len(parts) >= 3 and parts[0] == "catalog" and parts[1] != "_shared":
                changed.add(parts[1])
        shared_paths = sorted({path for path in paths if common_path(path)})
        modules = available if shared_paths else [name for name in available if name in changed]
        readme_only = bool(paths) and all(readme_path(path) for path in paths)
    chunks = [
        {"id": "-".join(selected), "modules": " ".join(selected)}
        for offset in range(0, len(modules), CHUNK_SIZE)
        for selected in [modules[offset:offset + CHUNK_SIZE]]
    ]
    return {
        "modules": modules, "chunks": chunks,
        "shared_paths": shared_paths, "readme_only": readme_only,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="Select every current catalog module")
    parser.add_argument("--base", help="Base Git commit or revision")
    parser.add_argument("--head", help="Head Git commit or revision")
    args = parser.parse_args()
    if args.all:
        if args.base is not None or args.head is not None:
            parser.error("--all cannot be combined with --base or --head")
    elif args.base is None or args.head is None:
        parser.error("specify --all, or both --base and --head")
    try:
        root = Path(os.fsdecode(git("rev-parse", "--show-toplevel")).strip())
        paths = None if args.all else changed_paths(root, args.base, args.head)
        result = plan(root, paths)
    except (OSError, ValueError) as error:
        print(f"plan-checks: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
