import os
from pathlib import Path

from terminal import TerminalError, TerminalProcess, TerminalTimeout


root = Path.cwd()


def run(name, shell, init, profile, color, personal=None, explicit=None, exit_key=b"q", project_name="project with spaces", non_theme=False):
    work = root / name
    work.mkdir()
    project = work / project_name
    project.mkdir()
    home = root / f"{name}-home"
    home.mkdir()
    config = home / "xdg"
    config.mkdir()
    if personal:
        (config / "yazi").mkdir()
        (config / "yazi" / "theme.toml").write_text(f'[mgr]\ncwd = {{ fg = "{personal}" }}\n')
    if explicit:
        explicit_config = home / "explicit-yazi"
        explicit_config.mkdir()
        (explicit_config / "theme.toml").write_text(f'[mgr]\ncwd = {{ fg = "{explicit}" }}\n')
    if non_theme:
        (config / "yazi").mkdir()
        (config / "yazi" / "keymap.toml").write_text(
            '[mgr]\nprepend_keymap = [{ on = "e", run = "enter" }]\n'
        )
        (config / "yazi" / ".personal-marker").write_text("retain me\n")
    personal_files = {
        path.name: path.read_bytes() for path in (config / "yazi").glob("*") if path.is_file()
    }
    temporary = work / "temporary"
    temporary.mkdir()
    result = home / "cwd"
    environment = {
        **os.environ,
        "HOME": str(home), "XDG_CONFIG_HOME": str(config),
        "XDG_CACHE_HOME": str(home / "cache"), "XDG_STATE_HOME": str(home / "state"),
        "TERM": "xterm-256color", "COLORTERM": "truecolor", "TMPDIR": str(temporary),
        "PATH": profile + "/bin:" + os.environ["PATH"],
        "LMX_INIT": init, "LMX_START": str(work), "LMX_RESULT": str(result),
    }
    if explicit:
        environment["YAZI_CONFIG_HOME"] = str(explicit_config)
    else:
        environment.pop("YAZI_CONFIG_HOME", None)
    arguments = [
        shell, "-c",
        'source "$LMX_INIT"; cd -- "$LMX_START"; y; printf %s "$PWD" > "$LMX_RESULT"',
    ]

    with TerminalProcess(arguments, env=environment, output_limit=262144) as process:
        replies = {
            b"\x1b[6n": (b"\x1b[1;1R", 0),
            b"\x1b]11;?": (b"\x1b]11;rgb:1e1e/1e1e/2e2e\x1b\\", 0),
        }

        def wait(condition, label):
            def ready():
                # Yazi's terminal queries belong to this scenario, not the PTY helper.
                for query, (reply, answered) in replies.items():
                    received = process.output.count(query)
                    for _ in range(answered, received):
                        process.send(reply)
                    replies[query] = (reply, received)
                return condition()

            process.until(ready, timeout=15, label=f"{name}: {label}")

        try:
            wait(lambda: color in process.output and b"project with spaces" in process.output, "directory and theme")
            assert b"Failed to" not in process.output, (name, process.output)
            rendered = len(process.output)
            process.send(b"e" if non_theme else b"l")
            wait(lambda: b"project with spaces" in process.output[rendered:], "entered directory")
            process.send(exit_key)
            status = process.wait(timeout=15)
            process.drain()
        except (TerminalError, TerminalTimeout) as error:
            raise AssertionError((name, str(error))) from error
        assert status == 0, (name, status, process.output)

    expected = work if exit_key == b"Q" else project
    assert result.read_bytes() == os.fsencode(expected), (name, result.read_bytes(), expected)
    assert not list(temporary.glob("limanix-yazi.*")), (name, "theme overlay was not cleaned")
    assert not list(temporary.glob("yazi-cwd.*")), (name, "cwd handoff was not cleaned")
    remaining = {
        path.name: path.read_bytes() for path in (config / "yazi").glob("*") if path.is_file()
    }
    assert remaining == personal_files, (name, "personal configuration changed")


profile = os.environ["LMX_YAZI_PROFILE"]
run("bash-default", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], profile, b"38;2;137;220;235")
run("zsh-default", os.environ["LMX_ZSH"], os.environ["LMX_ZSH_INIT"], profile, b"38;2;137;220;235")
run("personal", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], profile, b"38;2;255;0;0", personal="#ff0000")
run("explicit", os.environ["LMX_ZSH"], os.environ["LMX_ZSH_INIT"], profile, b"38;2;0;255;0", explicit="#00ff00")
run("managed", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], os.environ["LMX_YAZI_MANAGED_PROFILE"], b"38;2;18;52;86")
run("retain-cwd", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], profile, b"38;2;137;220;235", exit_key=b"Q")
run("newline-cwd", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], profile, b"38;2;137;220;235", project_name="project with spaces\n")

run("personal-keymap", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], profile, b"38;2;137;220;235", non_theme=True)
run("managed-explicit", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], os.environ["LMX_YAZI_MANAGED_PROFILE"], b"38;2;18;52;86", explicit="#00ff00")
run("managed-flavor", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], os.environ["LMX_YAZI_FLAVOR_PROFILE"], b"38;2;171;205;239")
