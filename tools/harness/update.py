import json
import re
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import UTC, datetime
from pathlib import Path

RELEASE_URL = re.compile(r'"github:NixOS/nixpkgs/nixos-(\d{2}\.\d{2})"')
REVISION_LINE = re.compile(r'^rev = "([0-9a-f]{40})"$')
CHANNELS = "https://channels.nixos.org"
FLAKE = "flake.nix"
LOCK = "flake.lock"
UNSTABLE = Path("catalog/_shared/unstable.toml")


def nixos_release(flake: str) -> str:
    found = RELEASE_URL.search(flake)
    if found is None:
        raise ValueError("flake.nix does not pin a NixOS release")
    return found.group(1)


def locked_nixpkgs(lock: str) -> tuple[str, str]:
    node = json.loads(lock)["nodes"]["nixpkgs"]["locked"]
    return node["rev"], day(node["lastModified"])


def day(timestamp: int) -> str:
    return datetime.fromtimestamp(timestamp, UTC).strftime("%Y%m%d")


def next_release(current: str) -> str:
    year, month = current.split(".")
    if month == "05":
        return f"{year}.11"
    if month == "11":
        return f"{int(year) + 1}.05"
    raise ValueError(f"Unexpected NixOS release {current}")


def unstable_revision(toml: str) -> str:
    revision = ""
    for line in toml.splitlines():
        found = REVISION_LINE.match(line)
        if found:
            revision = found.group(1)
    return revision


def moved_unstable(toml: str, revision: str, sha256: str) -> str:
    updated = []
    for line in toml.splitlines():
        if line.startswith("rev = "):
            line = f'rev = "{revision}"'
        elif line.startswith("sha256 = "):
            line = f'sha256 = "{sha256}"'
        updated.append(f"{line}\n")
    return "".join(updated)


def fetch(url: str) -> str:
    with urllib.request.urlopen(url) as response:
        return str(response.read().decode().strip())


def published(url: str) -> bool:
    try:
        fetch(url)
    except (urllib.error.HTTPError, urllib.error.URLError):
        return False
    return True


def update_flake_input() -> None:
    subprocess.run(["nix", "flake", "update", "nixpkgs"], check=True)


def nixpkgs() -> None:
    release = nixos_release(Path(FLAKE).read_text())
    before, _ = locked_nixpkgs(Path(LOCK).read_text())
    update_flake_input()
    after, date = locked_nixpkgs(Path(LOCK).read_text())
    print(f"Nixpkgs {release}: {before} -> {after}", file=sys.stderr)
    print(f"release={release}")
    print(f"before={before[:7]}")
    print(f"after={after[:7]}")
    print(f"date={date}")


def unstable() -> None:
    toml = UNSTABLE.read_text()
    before = unstable_revision(toml)
    after = fetch(f"{CHANNELS}/nixos-unstable/git-revision")
    if after != before:
        completed = subprocess.run(
            ["nix", "flake", "prefetch", "--json", f"github:NixOS/nixpkgs/{after}"],
            stdout=subprocess.PIPE,
            text=True,
            check=True,
        )
        prefetched = json.loads(completed.stdout)
        UNSTABLE.write_text(moved_unstable(toml, after, prefetched["hash"]))
        print(f"nixos-unstable: {before} -> {after}", file=sys.stderr)
        print(f"date={day(prefetched['lastModified'])}")
    print(f"before={before[:7]}")
    print(f"after={after[:7]}")


def nixos() -> None:
    flake = Path(FLAKE).read_text()
    current = nixos_release(flake)
    following = next_release(current)
    print(f"current={current}")
    if not published(f"{CHANNELS}/nixos-{following}/git-revision"):
        print(f"NixOS {following} is not published yet", file=sys.stderr)
        print("next=")
        return
    Path(FLAKE).write_text(
        flake.replace(f'nixpkgs/nixos-{current}"', f'nixpkgs/nixos-{following}"')
    )
    update_flake_input()
    print(f"NixOS {current} -> {following}", file=sys.stderr)
    print(f"next={following}")
