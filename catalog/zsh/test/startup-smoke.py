import os
from pathlib import Path

from terminal import TerminalError, TerminalProcess, TerminalTimeout


root = Path(os.environ["TMPDIR"])
activated = os.environ.get("LMX_ACTIVATED") == "1"
etc = root / "etc"
if not activated:
    etc.mkdir()
    for entry in Path(os.environ["LMX_ETC"]).iterdir():
        (etc / entry.name).symlink_to(entry)
    (etc / "group").write_text("smoke:x:1000:\n")


def run(name, personal=False, custom_directory=False, home=None):
    home = home or root / name
    home.mkdir(exist_ok=True)
    config = home / "configuration" if custom_directory else home
    config.mkdir(exist_ok=True)
    content = "LMX_PERSONAL=yes\nzsh-newuser-install() { print LMX_PERSONAL_NEWUSER; }\n"
    if personal:
        (config / ".zshrc").write_text(content)
    if not activated:
        (etc / "passwd").write_text(
            f"smoke:x:1000:1000:Smoke:{home}:{os.environ['LMX_ZSH']}\n"
        )

    environment = {
        **os.environ,
        "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
        "XDG_DATA_HOME": str(home / ".local/share"), "TERM": "xterm-256color",
        "LMX_EXPECT_PERSONAL": "yes" if personal else "no",
    }
    environment.pop("LMX_PERSONAL", None)
    if custom_directory:
        environment["ZDOTDIR"] = str(config)
    else:
        environment.pop("ZDOTDIR", None)
    command = [
        os.environ["LMX_ZSH"], "-l", "-i", "-c", "source " + os.environ["LMX_CHECK"],
    ]
    if not activated:
        command = [
            "proot", "-i", "1000:1000", "-b", str(etc) + ":/etc",
            "-b", os.environ["LMX_PROFILE"] + ":/run/current-system/sw",
            *command,
        ]

    with TerminalProcess(command, env=environment) as process:
        try:
            process.until(
                lambda: b"LMX_ZSH_STARTUP_OK" in process.output,
                timeout=60, label=f"{name}: Zsh startup assertions",
            )
            status = process.wait(timeout=5)
            process.drain()
        except (TerminalError, TerminalTimeout) as error:
            raise AssertionError((name, str(error))) from error
        output = process.output.decode(errors="replace")
        assert status == 0, (name, status, output)
        assert "LMX_ZSH_STARTUP_OK" in output, (name, output)
        assert "Z Shell configuration function for new users" not in output, (name, output)
        assert "zsh-newuser-install:" not in output, (name, output)

    if personal:
        assert (config / ".zshrc").read_text() == content, "personal startup file changed"
    else:
        for filename in (".zshenv", ".zprofile", ".zshrc", ".zlogin"):
            assert not (home / filename).exists(), (name, "startup file was created", filename)
    return home


fresh_home = run("fresh-login", home=Path(os.environ["HOME"]) if activated else None)
run("repeat-login", home=fresh_home)
run("personal-login", personal=True)
run("personal-directory", personal=True, custom_directory=True)
