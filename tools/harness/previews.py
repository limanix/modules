"""Write previews/, the theme previews that the site shows.

Nix builds tools/previews.nix, which draws the scene of every theme; this command copies the
result into previews/ and gives the files the owner of the repository.
"""

import os
import shutil
import subprocess
from pathlib import Path

from harness import REPOSITORY, nix

SOURCE = REPOSITORY / "tools" / "previews.nix"


def write(repository: Path = REPOSITORY) -> Path:
    built = subprocess.run(
        [
            "nix",
            *nix.FLAGS,
            "build",
            "--impure",
            "--no-link",
            "--print-out-paths",
            "--file",
            SOURCE,
        ],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    ).stdout.strip()
    target = repository / "previews"
    shutil.rmtree(target, ignore_errors=True)
    shutil.copytree(built, target)
    owner = repository.stat()
    for path in [target, *target.iterdir()]:
        path.chmod(0o755 if path.is_dir() else 0o644)
        os.chown(path, owner.st_uid, owner.st_gid)
    return target
