import os
from pathlib import Path
import shlex
import shutil
import time
import subprocess


source = os.environ["LMX_YAZI_SHELL_INIT"]
root = Path.cwd()
commands = root / "commands"
commands.mkdir()
temporary = root / "temporary"
temporary.mkdir()
marker = root / "yazi-started"
bash = os.environ["LMX_BASH"]


def script(name, content):
    path = commands / name
    path.write_text(f"#!{bash}\n" + content)
    path.chmod(0o755)


script("yazi", f"touch {shlex.quote(str(marker))}; exit 17\n")
environment = {**os.environ, "TMPDIR": str(temporary), "PATH": f"{commands}:{os.environ['PATH']}"}
for shell, arguments in [(bash, ["--noprofile", "--norc"]), (os.environ["LMX_ZSH"], ["-f"])]:
    result = subprocess.run(
        [shell, *arguments, "-c", f"set -e; source {shlex.quote(source)}; y"],
        env=environment, capture_output=True,
    )
    assert result.returncode == 17, (shell, result)
    assert marker.exists(), "Yazi was not launched"
    assert not list(temporary.iterdir()), "failed Yazi left its temporary handoff file"
    marker.unlink()

script("mktemp", "exit 73\n")
for shell, arguments in [(bash, ["--noprofile", "--norc"]), (os.environ["LMX_ZSH"], ["-f"])]:
    result = subprocess.run(
        [shell, *arguments, "-c", f"source {shlex.quote(source)}; y"],
        env=environment, capture_output=True,
    )
    assert result.returncode == 73, (shell, result)
    assert not marker.exists(), "Yazi launched without a handoff file"


# The runtime theme overlay must clean up even when Yazi fails or is interrupted.
overlay_home = root / "overlay-home"
personal = overlay_home / ".config/yazi"
personal.mkdir(parents=True)
personal_config = personal / "keymap.toml"
personal_config.write_text("personal keymap\n")
default = root / "default-theme"
default.mkdir()
theme = default / "theme.toml"
theme.write_text("default theme\n")
overlay_capture = root / "overlay-capture"
fake = root / "overlay-yazi"
fake.write_text(
    f"#!{bash}\n"
    f'printf %s "$YAZI_CONFIG_HOME" > {shlex.quote(str(overlay_capture))}\n'
    'test -L "$YAZI_CONFIG_HOME/keymap.toml" || exit 65\n'
    'test -L "$YAZI_CONFIG_HOME/theme.toml" || exit 66\n'
    'exit 17\n'
)
fake.chmod(0o755)
overlay_environment = {
    **os.environ,
    "HOME": str(overlay_home), "TMPDIR": str(temporary),
    "limanix_yazi_command": str(fake),
    "limanix_yazi_configuration": str(default), "limanix_yazi_theme": str(theme),
    "limanix_yazi_mktemp": shutil.which("mktemp"),
    "limanix_yazi_ln": shutil.which("ln"), "limanix_yazi_rm": shutil.which("rm"),
}
overlay_environment.pop("YAZI_CONFIG_HOME", None)
overlay_environment.pop("XDG_CONFIG_HOME", None)
result = subprocess.run(
    [bash, os.environ["LMX_YAZI_THEME_WRAPPER"]], env=overlay_environment, capture_output=True,
)
assert result.returncode == 17, result
assert not Path(overlay_capture.read_text()).exists(), "failed Yazi left its overlay"
assert personal_config.read_text() == "personal keymap\n"
assert not (personal / "theme.toml").exists(), "overlay changed personal theme configuration"

fake.write_text(
    f"#!{bash}\n"
    f'printf %s "$YAZI_CONFIG_HOME" > {shlex.quote(str(overlay_capture))}\n'
    f"exec {shlex.quote(shutil.which('sleep'))} 30\n"
)
overlay_capture.unlink()
process = subprocess.Popen(
    [bash, os.environ["LMX_YAZI_THEME_WRAPPER"]], env=overlay_environment,
    stdout=subprocess.PIPE, stderr=subprocess.PIPE,
)
try:
    deadline = time.monotonic() + 5
    while not overlay_capture.exists():
        assert process.poll() is None, process.communicate()
        assert time.monotonic() < deadline, "Yazi overlay did not start"
        time.sleep(0.01)
    process.terminate()
    process.communicate(timeout=5)
    assert process.returncode == 143, process.returncode
    assert not Path(overlay_capture.read_text()).exists(), "interrupted Yazi left its overlay"
    assert personal_config.read_text() == "personal keymap\n"
finally:
    if process.poll() is None:
        process.kill()
        process.communicate()
