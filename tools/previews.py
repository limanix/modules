"""Draw each theme's preview: a tmux window with Neovim, eza and delta, saved as SVG.

The scene runs the catalog's own configuration of each tool in a pseudo-terminal; pyte keeps the
screen that tmux draws, and the SVG paints it cell by cell in the theme's colors.
"""

import fcntl
import json
import os
import pty
import re
import select
import shlex
import struct
import subprocess
import sys
import tempfile
import termios
import time
from html import escape
from pathlib import Path
from typing import Any

import pyte

COLUMNS, ROWS = 120, 32
WIDTH, HEIGHT, FONT, PADDING = 8.4, 18.0, 14, 14
FONTS = (
    "'JetBrains Mono Variable', 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, monospace"
)
SAMPLE = """local M = {}

-- Greets every name on the list.
function M.greet(names, word)
  local lines = {}
  for index, name in ipairs(names) do
    lines[index] = word .. ", " .. name
  end
  return table.concat(lines, "\\n")
end

return M
"""
TERMINAL = {
    "black": "background_darker",
    "red": "red",
    "green": "green",
    "brown": "yellow",
    "blue": "blue",
    "magenta": "purple",
    "cyan": "cyan",
    "white": "subtle",
    "brightblack": "muted",
    "brightred": "red",
    "brightgreen": "green",
    "brightbrown": "yellow",
    "brightblue": "blue",
    "brightmagenta": "pink",
    "brightcyan": "cyan",
    "brightwhite": "foreground",
}


class Screen(pyte.Screen):
    def report_device_status(self, mode: int, **_: Any) -> None:
        pass


def project(directory: Path) -> None:
    (directory / "src").mkdir()
    (directory / "init.lua").write_text(SAMPLE)
    (directory / "README.md").write_text("# Greeter\n")
    (directory / "notes.txt").write_text("todo\n")
    (directory / "run.sh").write_text("#!/bin/sh\nnvim init.lua\n")
    (directory / "run.sh").chmod(0o755)
    (directory / "src" / "util.lua").write_text("return {}\n")
    (directory / "docs").symlink_to("src")
    git = ["git", "-c", "user.name=LimaNix", "-c", "user.email=preview@limanix.dev"]
    subprocess.run([*git, "init", "-q"], cwd=directory, check=True)
    subprocess.run([*git, "add", "."], cwd=directory, check=True)
    subprocess.run([*git, "commit", "-qm", "greeter"], cwd=directory, check=True)
    changed = SAMPLE.replace("= word ..", '= (word or "Hi") ..').replace(
        "return M", 'M.version = "1.0"\n\nreturn M'
    )
    (directory / "init.lua").write_text(changed)
    for path in directory.rglob("*"):
        if ".git" not in path.parts:
            os.utime(path, (1735732800, 1735732800), follow_symlinks=False)


def configuration(source: str, target: Path) -> None:
    text = Path(source).read_text()
    text = text.replace("#(/run/current-system/sw/bin/lmx status --short)", "")
    text = text.replace("%a %d %b", "Wed 01 Jan").replace("%H:%M", "12:00")
    target.write_text(text)


def capture(scene: dict[str, Any], home: Path) -> pyte.Screen:
    directory = home / "greeter"
    directory.mkdir()
    project(directory)
    (home / ".gitconfig").write_text(Path(scene["gitconfig"]).read_text())
    configuration(scene["tmux"], home / "tmux.conf")
    tools = ":".join(str(Path(tool).parent) for tool in (scene["neovim"], scene["delta"]))
    prefix = (
        f". {shlex.quote(scene['environment'])}; "
        f"export PATH={tools}:{os.environ['PATH']}; cd {directory}; "
    )
    environment = {
        **os.environ,
        "HOME": str(home),
        "TMUX_TMPDIR": str(home),
        "TERM": "xterm-256color",
        "COLORTERM": "truecolor",
        "LANG": "C.UTF-8",
    }
    commands = {
        "editor": "nvim -c 'set number' init.lua",
        "files": "eza -l --git --no-user --time-style=long-iso; exec sleep 600",
        "diff": "git --no-pager diff | delta --paging=never; exec sleep 600",
    }
    shell = {name: prefix + command for name, command in commands.items()}
    tmux = ["tmux", "-u", "-L", "preview", "-f", str(home / "tmux.conf")]
    size = ["-x", str(COLUMNS), "-y", str(ROWS - 1)]
    for command in (
        ["new-session", "-d", "-s", "work", "-n", "nvim", *size, shell["editor"]],
        ["split-window", "-h", "-l", "52", shell["files"]],
        ["split-window", "-v", "-l", "22", shell["diff"]],
        ["select-pane", "-t", "work:0.0"],
    ):
        subprocess.run([*tmux, *command], env=environment, check=True)
    screen = Screen(COLUMNS, ROWS)
    stream = pyte.ByteStream(screen)
    pid, descriptor = pty.fork()
    if pid == 0:
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", ROWS, COLUMNS, 0, 0))
        os.execvpe(tmux[0], [*tmux, "attach", "-t", "work"], environment)
    os.set_blocking(descriptor, False)
    deadline = time.monotonic() + 60
    quiet = time.monotonic()
    try:
        while time.monotonic() < deadline:
            ready, _, _ = select.select([descriptor], [], [], 0.2)
            if ready:
                try:
                    data = os.read(descriptor, 65536)
                except OSError:
                    break
                if data:
                    stream.feed(data)
                    quiet = time.monotonic()
            text = "\n".join(screen.display)
            settled = time.monotonic() - quiet > 2
            if settled and all(marker in text for marker in ("M.greet", "run.sh", "= word ..")):
                break
        else:
            lines = "\n".join(screen.display)
            raise SystemExit(f"{scene['name']}: the scene did not settle:\n{lines}")
    finally:
        subprocess.run([*tmux, "kill-server"], env=environment, check=False)
        os.close(descriptor)
        os.waitpid(pid, 0)
    return screen


def paint(color: str, palette: dict[str, str], default: str) -> str:
    if color == "default":
        return default
    if color in TERMINAL:
        return palette[TERMINAL[color]]
    return "#" + color.lower()


def svg(screen: pyte.Screen, scene: dict[str, Any]) -> str:
    palette = scene["palette"]
    width = COLUMNS * WIDTH + 2 * PADDING
    height = ROWS * HEIGHT + 2 * PADDING
    shapes: list[str] = []
    texts: list[str] = []
    for row in range(ROWS):
        line = screen.buffer[row]
        cells = []
        for column in range(COLUMNS):
            cell = line[column]
            foreground = paint(cell.fg, palette, palette["foreground"])
            background = paint(cell.bg, palette, palette["background"])
            if cell.reverse:
                foreground, background = background, foreground
            cells.append(
                (cell.data or " ", foreground, background, cell.bold, cell.italics, cell.underscore)
            )
        y = PADDING + row * HEIGHT
        column = 0
        while column < COLUMNS:
            background = cells[column][2]
            end = column
            while end < COLUMNS and cells[end][2] == background:
                end += 1
            if background != palette["background"]:
                shapes.append(
                    f'<rect x="{PADDING + column * WIDTH:.1f}" y="{y:.1f}" '
                    f'width="{(end - column) * WIDTH:.1f}" height="{HEIGHT:.1f}" '
                    f'fill="{background}"/>'
                )
            column = end
        column = 0
        while column < COLUMNS:
            style = cells[column][1:2] + cells[column][3:]
            end = column
            while end < COLUMNS and cells[end][1:2] + cells[end][3:] == style:
                end += 1
            run = "".join(cell[0] for cell in cells[column:end])
            attributes = f'fill="{style[0]}"'
            if style[1]:
                attributes += ' font-weight="700"'
            if style[2]:
                attributes += ' font-style="italic"'
            if style[3]:
                attributes += ' text-decoration="underline"'
            # One text per word: SVG viewers collapse runs of spaces.
            for word in re.finditer(r"\S+", run):
                texts.append(
                    f'<text x="{PADDING + (column + word.start()) * WIDTH:.1f}" '
                    f'y="{y + HEIGHT * 0.75:.1f}" {attributes}>{escape(word.group())}</text>'
                )
            column = end
    title = escape(scene["title"])
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" '
        f'viewBox="0 0 {width:.0f} {height:.0f}" role="img" aria-label="{title}">\n'
        f"<title>{title}</title>\n"
        f'<rect width="100%" height="100%" rx="10" fill="{palette["background"]}"/>\n'
        + "\n".join(shapes)
        + f'\n<g font-family="{FONTS}" font-size="{FONT}">\n'
        + "\n".join(texts)
        + "\n</g>\n</svg>\n"
    )


def main() -> None:
    scenes = json.loads(Path(sys.argv[1]).read_text())
    output = Path(sys.argv[2])
    output.mkdir()
    themes = []
    for scene in sorted(scenes, key=lambda item: item["title"]):
        with tempfile.TemporaryDirectory() as home:
            screen = capture(scene, Path(home))
        (output / f"{scene['name']}.svg").write_text(svg(screen, scene))
        keys = ("name", "title", "homepage", "dark", "palette")
        themes.append({key: scene[key] for key in keys})
    (output / "themes.json").write_text(json.dumps(themes, indent=2) + "\n")


if __name__ == "__main__":
    main()
