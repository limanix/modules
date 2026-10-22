"""Check Limanix's literal session names, attachment and argument contract."""

import os
import subprocess

from terminal import TerminalError, TerminalProcess


provider = os.environ["LMX_SESSION_COMMAND"]
tmux = os.environ["LMX_TMUX"]


def run_tmux(*arguments):
    return subprocess.run(
        [tmux, *arguments], capture_output=True, check=True, timeout=10,
    ).stdout


def attach(name):
    matches = []

    def attached():
        clients = subprocess.run(
            [tmux, "list-clients", "-F", "#{session_id}\t#{session_name}"],
            capture_output=True, timeout=10,
        )
        matches[:] = [
            line.split(b"\t", 1)[0]
            for line in clients.stdout.splitlines()
            if line.partition(b"\t")[2] == name.encode()
        ]
        return bool(matches)

    with TerminalProcess([provider, name]) as process:
        try:
            process.until(attached, timeout=15, label=f"attach {name!r}")
            session = matches[0].decode()
            run_tmux("detach-client", "-s", session)
            status = process.wait(timeout=5)
        except TerminalError as error:
            raise AssertionError((name, str(error))) from error
        assert status == 0, (name, status, process.diagnostic())
        return session


try:
    for name in ["work", "--help", "work;", "#(touch unwanted)#{session_name}#[red]"]:
        session = attach(name)
        assert attach(name) == session, ("reattach created another session", name)
    assert not os.path.exists("unwanted"), "session name executed a command"
    before = run_tmux("list-sessions", "-F", "#{session_name}")
    for arguments in [[], [""], ["one", "two"], ["project.name"], ["project:name"]]:
        result = subprocess.run([provider, *arguments], capture_output=True, timeout=10)
        assert result.returncode == 64, (arguments, result)
        assert result.stderr, ("missing session diagnostic", arguments)
    assert run_tmux("list-sessions", "-F", "#{session_name}") == before
finally:
    subprocess.run([tmux, "kill-server"], capture_output=True, timeout=5)
