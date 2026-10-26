#!/usr/bin/env python3
"""Let Nix call the cache writer after a build.

The check runner gives Nix this file as its post-build-hook program.
Nix supplies the built output paths through the OUT_PATHS environment variable.
The runner supplies the cache directory through NIX_BUILD_CACHE.

This script adds tools/ to the Python import path and calls cache.hook().
It gives Nix the exit code returned by the cache writer.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from harness.cache import hook

if __name__ == "__main__":
    sys.exit(hook())
