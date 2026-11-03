"""Write Spaceship settings for the guest: each section's color by role, plain symbols, the lmx words."""

import json
import os
import re
import sys
from pathlib import Path

root, target = Path(sys.argv[1]), Path(sys.argv[2])
colors = json.loads(os.environ["colors"])
symbols = json.loads(os.environ["symbols"])
default = re.compile(r'^\s*(SPACESHIP_[A-Z0-9_]+)="\$\{\1=(.*)\}"\s*$')


def private(value: str) -> bool:
    return any(0xE000 <= ord(char) <= 0xF8FF or ord(char) >= 0xF0000 for char in value)


lines = []
for path in sorted(root.rglob("*.zsh")):
    for line in path.read_text().splitlines():
        match = default.match(line)
        if not match:
            continue
        name, value = match[1], match[2].strip('"')
        if name.endswith("_COLOR") or "_COLOR_" in name:
            if value not in colors:
                raise SystemExit(f"spaceship: no role for {name}={value}")
            lines.append(f"{name}='{colors[value]}'")
        elif private(value):
            if name not in symbols:
                raise SystemExit(f"spaceship: {name} needs a plain symbol")
            lines.append(f"{name}={json.dumps(symbols[name])}")
target.write_text("\n".join(lines) + "\n" + os.environ["extra"])
