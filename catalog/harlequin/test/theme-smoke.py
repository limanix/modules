import os
from pathlib import Path
from unittest.mock import patch

from click.testing import CliRunner
from harlequin import cli


themes = []


def capture_theme(app):
    themes.append(app.theme)


def check_theme(arguments, expected):
    result = CliRunner().invoke(
        cli.build_cli(), ["--adapter", "sqlite", ":memory:", *arguments]
    )
    assert result.exit_code == 0, (result.output, result.exception)
    assert themes.pop() == expected, expected


with patch.object(cli.Harlequin, "run", capture_theme):
    check_theme([], "catppuccin-mocha")
    config = Path(os.environ["XDG_CONFIG_HOME"]) / "harlequin" / "config.toml"
    config.write_text(
        'default_profile = "personal"\n[profiles.personal]\ntheme = "harlequin"\n'
    )
    check_theme([], "harlequin")
    check_theme(["--theme", "textual-dark"], "textual-dark")
