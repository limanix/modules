import json
import re
import sys

theme, palette, colors = sys.argv[1:]
mocha = {
    value["hex"].lower().lstrip("#"): name
    for name, value in json.load(open(palette))["mocha"]["colors"].items()
}
target = {name: value.lstrip("#") for name, value in json.load(open(colors)).items()}


def replace(match):
    value = match.group(1) or match.group(2)
    color = target.get(mocha.get(value.lower()), value)
    return "#" + color if match.group(1) else color


text = re.sub(
    r"#([0-9A-Fa-f]{6})|(?<![0-9A-Fa-f#])([0-9A-Fa-f]{6})(?![0-9A-Fa-f])",
    replace,
    open(theme).read(),
)
sys.stdout.write(text.replace("<string>Catppuccin Mocha</string>", "<string>limanix</string>", 1))
