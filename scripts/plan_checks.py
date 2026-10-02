"""Select changed catalog modules and split them into CI jobs."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tomllib
from pathlib import Path

COMMON_FILES = frozenset(
    {
        "Taskfile.yml",
        ".taskrc.yml",
        "flake.nix",
        "flake.lock",
        "interface.nix",
        "scripts/run_checks.sh",
        "scripts/cache_nix_build.sh",
        "scripts/plan_checks.py",
        "scripts/tests/test_plan_checks.py",
        "scripts/tests/test_run_checks.py",
    }
)
PALETTE_CONSUMERS = frozenset({"lazygit", "tmux", "yazi", "zsh"})


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


def catalog_names(root: Path) -> list[str]:
    names = []
    for entry in (root / "catalog").iterdir():
        if not entry.is_dir() or entry.name == "_shared":
            continue
        if (
            entry.is_symlink()
            or not re.fullmatch(r"[a-z][a-z0-9]*(-[a-z0-9]+)*", entry.name)
            or len(entry.name) > 63
        ):
            raise ValueError(f"invalid catalog module directory: {entry.name}")
        names.append(entry.name)
    return sorted(names)


def common_path(path: str) -> bool:
    return not readme_path(path) and (
        path in COMMON_FILES
        or path.startswith(("checks/", ".github/workflows/", "catalog/_shared/"))
    )


def readme_path(path: str) -> bool:
    return path.rsplit("/", 1)[-1] == "README.md"


def dependents(root: Path, names: list[str], changed: set[str]) -> set[str]:
    """Include consumers of sibling catalog files, including transitive imports.

    Scan all Nix paths rather than imports alone: tests and package helpers also
    depend on siblings. Comments and strings can overselect, but cannot remove
    coverage. A computed path into the catalog conservatively selects its owner
    whenever any catalog module changes.
    """
    catalog = root / "catalog"
    references = re.compile(r"(?<![\w/])(?:\.{1,2}/)+[\w./-]*")
    dependencies: dict[str, set[str]] = {}
    for name in names:
        required = set()
        for source in (catalog / name).rglob("*.nix"):
            for match in references.finditer(source.read_text()):
                resolved = (source.parent / match.group()).resolve()
                try:
                    relative = resolved.relative_to(catalog.resolve())
                except ValueError:
                    continue
                if not relative.parts:
                    required.update(names)
                elif relative.parts[0] not in (name, "_shared"):
                    required.add(relative.parts[0])
        dependencies[name] = required
    selected = set(changed)
    while True:
        consumers = {
            name for name, required in dependencies.items() if required & selected
        }
        if consumers <= selected:
            return selected
        selected.update(consumers)


def changed_paths(root: Path, base: str, head: str) -> list[str]:
    output = git(
        "diff", "--name-only", "--no-renames", "-z", base, head, "--", root=root
    )
    return [os.fsdecode(path) for path in output.split(b"\0") if path]


def documentation_path(path: str) -> bool:
    return Path(path).suffix.lower() in {".md", ".rst"}


def numeric_entrypoint(path: str) -> str | None:
    parts = path.split("/")
    if len(parts) != 4 or parts[0] != "catalog" or parts[2] != "versions":
        return None
    match = re.fullmatch(r"([0-9]+(?:\.[0-9]+)*)\.nix", parts[3])
    return match.group(1) if match else None


def declared_versions(root: Path, name: str) -> list[str]:
    metadata_path = root / "catalog" / name / "module.toml"
    if metadata_path.is_symlink():
        raise ValueError(f"module metadata must be a regular file: {name}")
    versions = tomllib.loads(metadata_path.read_text()).get("versions", [])
    if (
        not isinstance(versions, list)
        or any(
            not isinstance(version, str)
            or len(version) > 63
            or not re.fullmatch(r"[0-9]+(\.[0-9]+)*", version)
            for version in versions
        )
        or len(versions) != len(set(versions))
    ):
        raise ValueError(f"invalid declared versions: {name}")
    return versions


def palette_has_only_unversioned_consumers(root: Path, names: list[str]) -> bool:
    """Permit the known palette data update only while its scope stays explicit."""
    shared = root / "catalog" / "_shared"
    if any(
        any(token in source.read_text() for token in ["palette", "readFile", "readDir"])
        for source in shared.rglob("*.nix")
    ):
        return False
    direct_palette = re.compile(
        r"(?<![\w/])(?:\.{1,2}/)+_shared/palette\.toml(?![\w./-])"
    )
    consumers = set()
    for name in names:
        for source in (root / "catalog" / name).rglob("*.nix"):
            text = source.read_text()
            if "_shared" not in text:
                continue
            # Unknown or computed shared reads may reach the palette. Only the
            # known direct paths qualify; no private Nix expressions are parsed.
            if name not in PALETTE_CONSUMERS or "_shared" in direct_palette.sub(
                "", text
            ):
                return False
            consumers.add(name)
    return bool(consumers) and all(
        not declared_versions(root, name) for name in consumers
    )


def full_runtime_modules(
    root: Path, names: list[str], paths: list[str] | None
) -> set[str]:
    if paths is None:
        return set(names)
    source_changes = set()
    for path in paths:
        if documentation_path(path):
            continue
        if path in {"flake.nix", "flake.lock", "interface.nix"} or path.startswith(
            "checks/"
        ):
            return set(names)
        if path.startswith("catalog/_shared/"):
            if (
                path == "catalog/_shared/palette.toml"
                and palette_has_only_unversioned_consumers(root, names)
            ):
                continue
            return set(names)
        parts = path.split("/")
        if len(parts) < 3 or parts[0] != "catalog":
            continue
        if numeric_entrypoint(path) is not None:
            continue
        source_changes.add(parts[1])
    return dependents(root, names, source_changes) if source_changes else set()


def runtime_selection(
    root: Path, name: str, paths: list[str] | None, full: set[str]
) -> dict[str, str]:
    """Keep complete runtime checks for shared code and target changed selectors."""
    prefix = f"catalog/{name}/"
    changed = [
        path
        for path in paths or []
        if path.startswith(prefix) and not documentation_path(path)
    ]
    changed_versions = [
        (path, version)
        for path in changed
        if (version := numeric_entrypoint(path)) is not None
    ]
    versions = set()
    if changed_versions:
        declared = declared_versions(root, name)
        for path, version in changed_versions:
            if len(version) > 63:
                raise ValueError(f"invalid changed version path: {path}")
            if version not in declared:
                if (root / path).exists() or (root / path).is_symlink():
                    raise ValueError(
                        f"changed version is not declared in module.toml: {path}"
                    )
                return {"runtime_profile": "all", "runtime_versions": ""}
            versions.add(version)
    if name in full:
        return {"runtime_profile": "all", "runtime_versions": ""}
    return {"runtime_profile": "pr", "runtime_versions": " ".join(sorted(versions))}


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
        selected = (
            dependents(root, available, changed)
            if changed and not shared_paths
            else changed
        )
        modules = (
            available
            if shared_paths
            else [name for name in available if name in selected]
        )
        readme_only = bool(paths) and all(readme_path(path) for path in paths)
    full = full_runtime_modules(root, available, paths)
    chunks = [
        {"id": name, "modules": name, **runtime_selection(root, name, paths, full)}
        for name in modules
    ]
    return {
        "modules": modules,
        "chunks": chunks,
        "shared_paths": shared_paths,
        "readme_only": readme_only,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--all", action="store_true", help="Select every current catalog module"
    )
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
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(f"plan-checks: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
