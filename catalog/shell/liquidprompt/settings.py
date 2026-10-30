"""Write a liquidpromptrc that recomputes Liquidprompt's default colors from the guest's palette."""

import json
import os
import re
import sys
from pathlib import Path

source, target = sys.argv[1:]
colors = json.loads(os.environ["colors"])
assignment = re.compile(r'^\s*(LP_COLOR[A-Z0-9_]*)="?\$\{\1:-(.*)\}"?\s*$')
formats = {"8 -1 0 0 -1": "$LMX_MUTED", "-1 -1 1 0": "$BOLD"}
lines = [f"{name}=\"${{_LP_OPEN_ESC}}\"$'\\e[{sgr}m'\"${{_LP_CLOSE_ESC}}\"" for name, sgr in colors.items()]
text = Path(source).read_text()
body = text[text.index("__lp_source_config() {") :]
body = body[: body.index("\n}\n")]
current = None
inside = False
mapped = False
for line in body.splitlines():
    stripped = line.strip()
    if stripped.startswith("lp_terminal_format "):
        arguments = stripped.removeprefix("lp_terminal_format ")
        if arguments not in formats:
            raise SystemExit(f"liquidprompt: no color for lp_terminal_format {arguments}")
        current = formats[arguments]
        continue
    if stripped == "LP_COLORMAP=(" and not mapped:
        inside = mapped = True
        lines.append("LP_COLORMAP=(")
        continue
    if inside:
        lines.append("    " + stripped.split("#")[0].strip())
        if stripped == ")":
            inside = False
        continue
    match = assignment.match(line)
    if not match:
        continue
    value = match[2].strip('"')
    if value == "$lp_terminal_format":
        if current is None:
            raise SystemExit(f"liquidprompt: {match[1]} has no format")
        value = current
    elif value and not re.fullmatch(r"\$[A-Z_]+", value):
        raise SystemExit(f"liquidprompt: unexpected default {match[1]}={value}")
    lines.append(f'{match[1]}="{value}"')
if not mapped:
    raise SystemExit("liquidprompt: no LP_COLORMAP")
Path(target).write_text("\n".join(lines) + "\n")
