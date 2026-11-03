"""Turn Powerlevel10k's eight-color lean style into the guest's: role colors, plain symbols, no wizard."""

import json
import os
import re
import sys
from pathlib import Path

source, target = sys.argv[1:]
colors = json.loads(os.environ["colors"])
text = Path(source).read_text()


def color(number: str) -> str:
    if number not in colors:
        raise SystemExit(f"powerlevel10k: no role for color {number}")
    return colors[number]


text = re.sub(
    r"(_(?:FOREGROUND|BACKGROUND|COLOR))=([0-9]+)\b",
    lambda match: f"{match[1]}='{color(match[2])}'",
    text,
)
text = re.sub(r"%([0-9]+)F", lambda match: "%F{" + color(match[1]) + "}", text)
for old, new in {
    "typeset -g POWERLEVEL9K_MODE=nerdfont-complete": "typeset -g POWERLEVEL9K_MODE=ascii",
    "typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose": "typeset -g POWERLEVEL9K_INSTANT_PROMPT=off",
    "typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}": (
        "typeset -g POWERLEVEL9K_CONFIG_FILE=${ZDOTDIR:-$HOME}/.p10k.zsh"
    ),
    "  # If p10k is already loaded, reload configuration.": (
        os.environ["extra"] + "\n  # If p10k is already loaded, reload configuration."
    ),
}.items():
    if text.count(old) != 1:
        raise SystemExit(f"powerlevel10k: expected one {old!r}")
    text = text.replace(old, new)
Path(target).write_text(text)
