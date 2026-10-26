"""Keep a file-based Nix cache for later CI runs.

The post-build hook passes new output paths to this module.
It copies these paths and their dependencies into NIX_BUILD_CACHE with nix copy.
A failed copy or a copy timeout is reported as a skipped cache write.
GitHub Actions saves and restores the cache directory between runs.

After checks, the runner writes paths to keep into the .live file.
The prune command removes other cache entries and unused archives.
It keeps the cache data when that list is missing or marked as incomplete.
"""

import os
import subprocess
import sys
from collections.abc import Mapping
from pathlib import Path

COPY_TIMEOUT = 120
LIVE_FILE = ".live"


def encode_uri(path: str) -> str:
    encoded = path
    for character, replacement in (
        ("%", "%25"),
        (" ", "%20"),
        ("#", "%23"),
        ("?", "%3F"),
        ("&", "%26"),
        ("+", "%2B"),
    ):
        encoded = encoded.replace(character, replacement)
    return encoded


def skip(reason: str) -> int:
    print(f"cache-nix-build: skipping optional cache: {reason}", file=sys.stderr)
    return 0


def hook(environment: Mapping[str, str] = os.environ) -> int:
    cache_directory = environment.get("NIX_BUILD_CACHE", "")
    if not cache_directory.startswith("/"):
        return skip("cache path must be absolute")
    output_paths = environment.get("OUT_PATHS", "").split()
    if not output_paths:
        return 0
    if any(not path.startswith("/") for path in output_paths):
        return skip("output path must be absolute")
    try:
        Path(cache_directory).mkdir(parents=True, exist_ok=True)
    except OSError:
        return skip("cache directory is not writable")
    store = f"file://{encode_uri(cache_directory)}?compression=zstd&compression-level=1"
    try:
        completed = subprocess.run(
            ["nix", "copy", "--to", store, *output_paths], timeout=COPY_TIMEOUT, check=False
        )
    except subprocess.TimeoutExpired:
        return skip("nix copy failed or timed out")
    if completed.returncode != 0:
        return skip("nix copy failed or timed out")
    return 0


def prune(cache_directory: Path) -> None:
    live_file = cache_directory / LIVE_FILE
    if not live_file.is_file():
        print("prune-nix-cache: no live list; cache unchanged", file=sys.stderr)
        return
    live_hashes: set[str] = set()
    for store_path in live_file.read_text().splitlines():
        if not store_path:
            continue
        if store_path == "*":
            live_file.unlink()
            print("prune-nix-cache: incomplete live list; cache unchanged", file=sys.stderr)
            return
        store_name = store_path.removeprefix("/nix/store/")
        live_hashes.add(store_name.split("-", 1)[0])

    referenced: set[str] = set()
    for narinfo in sorted(cache_directory.glob("*.narinfo")):
        if narinfo.stem in live_hashes:
            for line in narinfo.read_text().splitlines():
                if line.startswith("URL: "):
                    referenced.add(line.removeprefix("URL: "))
        else:
            narinfo.unlink()
    nar_directory = cache_directory / "nar"
    if nar_directory.is_dir():
        for nar in sorted(nar_directory.iterdir()):
            if f"nar/{nar.name}" not in referenced:
                nar.unlink()
    live_file.unlink()
