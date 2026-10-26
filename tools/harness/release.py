"""Prepare version names and disk files for a catalog release.

The release command has three actions:
- tag: read Git tags and print the next vN name if HEAD has no release tag.
- build: ask Nix for the disk image and copy it into dist/ with its SHA-256 hash.
- manifest: write dist/image.json with download links and hashes for both systems.

These helpers give the workflows the names and files they need.
The workflows create the Git tag and publish the GitHub release.
"""

import hashlib
import json
import re
import shutil
import subprocess
import sys
from collections.abc import Iterable
from pathlib import Path

RELEASE_TAG = re.compile(r"^v[1-9][0-9]*$")
ARCHITECTURES = ("aarch64", "x86_64")
DOWNLOADS = "https://github.com/limanix/modules/releases/download"


def next_tag(head_tags: Iterable[str], all_tags: Iterable[str]) -> str:
    if any(RELEASE_TAG.match(tag) for tag in head_tags):
        print("HEAD is released already", file=sys.stderr)
        return ""
    numbers = [int(tag[1:]) for tag in all_tags if RELEASE_TAG.match(tag)]
    return f"v{max(numbers, default=0) + 1}"


def git_tags(arguments: list[str]) -> list[str]:
    completed = subprocess.run(
        ["git", "tag", *arguments], stdout=subprocess.PIPE, text=True, check=True
    )
    return completed.stdout.split()


def tag() -> None:
    print(f"tag={next_tag(git_tags(['--points-at', 'HEAD']), git_tags(['--list', 'v*']))}")


def manifest(release: str, dist: Path) -> None:
    def checksum(arch: str) -> str:
        return (dist / f"limanix-{arch}.qcow2.sha256").read_text().split()[0]

    document = {
        "version": release,
        "systems": {
            f"{arch}-linux": {
                "url": f"{DOWNLOADS}/{release}/limanix-{arch}.qcow2",
                "sha256": checksum(arch),
            }
            for arch in ARCHITECTURES
        },
    }
    (dist / "image.json").write_text(json.dumps(document, indent=2) + "\n")


def build(arch: str, dist: Path) -> None:
    subprocess.run(
        ["git", "config", "--global", "--add", "safe.directory", str(Path.cwd())], check=True
    )
    completed = subprocess.run(
        [
            "nix",
            "--extra-experimental-features",
            "nix-command flakes",
            "--option",
            "build-users-group",
            "nixbld",
            "build",
            "--no-link",
            "--print-out-paths",
            "--print-build-logs",
            f".#packages.{arch}-linux.image",
        ],
        stdout=subprocess.PIPE,
        text=True,
        check=True,
    )
    source = Path(completed.stdout.strip())
    name = f"limanix-{arch}.qcow2"
    target = dist / name
    dist.mkdir(parents=True, exist_ok=True)
    target.unlink(missing_ok=True)
    checksum_file = dist / f"{name}.sha256"
    checksum_file.unlink(missing_ok=True)
    shutil.copyfile(source, target)
    target.chmod(0o644)
    digest = hashlib.file_digest(target.open("rb"), "sha256").hexdigest()
    checksum_file.write_text(f"{digest}  {name}\n")
