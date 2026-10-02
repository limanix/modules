import hashlib
import os
from pathlib import Path
import pty
import re
import select
import shlex
import subprocess
import time


command = os.environ["LMX_PROJECT_COMMAND"]
tmux = os.environ["LMX_TMUX"]
state = Path(os.environ["LMX_WORKSPACE_STATE"])
root = Path.cwd()


def run_tmux(*arguments, check=True):
    return subprocess.run([tmux, *arguments], capture_output=True, check=check)


def session_name(directory):
    physical = directory.resolve()
    name = re.sub(r"[^a-zA-Z0-9_-]", "-", physical.name)[:24] or "root"
    identity = hashlib.sha256(os.fsencode(physical)).hexdigest()[:16]
    return f"project-{name}-{identity}"


def attach(directory, *, arguments=None, switch_directory=None, program=command):
    session = session_name(directory)
    child, terminal = pty.fork()
    if child == 0:
        os.chdir(directory if arguments == [] else root)
        os.execv(program, [program, *([str(directory)] if arguments is None else arguments)])
    output = bytearray()
    reaped = False
    try:
        deadline = time.monotonic() + 15
        while True:
            clients = run_tmux("list-clients", "-F", "#{session_name}", check=False)
            if session.encode() in clients.stdout.splitlines():
                break
            if select.select([terminal], [], [], 0.05)[0]:
                try:
                    output.extend(os.read(terminal, 65536))
                except OSError:
                    pass
            completed, status = os.waitpid(child, os.WNOHANG)
            if completed:
                reaped = True
                raise AssertionError(("workspace did not attach", directory, status, output))
            if time.monotonic() >= deadline:
                raise AssertionError(("workspace attach timed out", directory, output))
        if switch_directory is not None:
            run_tmux("select-window", "-t", f"{session}:shell")
            run_tmux(
                "send-keys", "-t", f"{session}:shell",
                shlex.join([command, str(switch_directory)]), "Enter",
            )
            session = session_name(switch_directory)
            deadline = time.monotonic() + 10
            while session.encode() not in run_tmux("list-clients", "-F", "#{session_name}").stdout.splitlines():
                assert time.monotonic() < deadline, "workspace did not switch the attached client"
                if select.select([terminal], [], [], 0.05)[0]:
                    os.read(terminal, 65536)
        run_tmux("detach-client", "-s", f"={session}")
        deadline = time.monotonic() + 5
        while True:
            completed, status = os.waitpid(child, os.WNOHANG)
            if completed:
                reaped = True
                assert os.waitstatus_to_exitcode(status) == 0, status
                break
            assert time.monotonic() < deadline, "workspace did not detach"
            time.sleep(0.05)
    finally:
        os.close(terminal)
        if not reaped:
            os.kill(child, 9)
            os.waitpid(child, 0)
    return session


def attach_pair(directory):
    session = session_name(directory)
    race = root / "creation-race"
    race.mkdir()
    children = []
    reaped = set()
    try:
        for _ in range(2):
            child, terminal = pty.fork()
            if child == 0:
                os.environ["LMX_WORKSPACE_RACE_DIR"] = str(race)
                program = os.environ["LMX_PROJECT_RACE_COMMAND"]
                os.execv(program, [program, str(directory)])
            children.append((child, terminal, bytearray()))
        deadline = time.monotonic() + 15
        while True:
            clients = run_tmux("list-clients", "-F", "#{session_name}", check=False)
            if clients.stdout.splitlines().count(session.encode()) == 2:
                break
            for child, terminal, output in children:
                if select.select([terminal], [], [], 0.02)[0]:
                    try:
                        output.extend(os.read(terminal, 65536))
                    except OSError:
                        pass
                completed, status = os.waitpid(child, os.WNOHANG)
                if completed:
                    reaped.add(child)
                    raise AssertionError(("concurrent workspace exited before attachment", status, output))
            assert time.monotonic() < deadline, "concurrent workspace did not attach both callers"
        workspace_panes(session, directory)
        run_tmux("detach-client", "-s", f"={session}")
        deadline = time.monotonic() + 5
        while len(reaped) != len(children):
            for child, terminal, output in children:
                if child in reaped:
                    continue
                if select.select([terminal], [], [], 0.02)[0]:
                    try:
                        output.extend(os.read(terminal, 65536))
                    except OSError:
                        pass
                completed, status = os.waitpid(child, os.WNOHANG)
                if completed:
                    reaped.add(child)
                    assert os.waitstatus_to_exitcode(status) == 0, (status, output)
            assert time.monotonic() < deadline, "concurrent workspace did not detach"
        assert len(list(race.iterdir())) == 2, "fixture did not synchronize both initial misses"
    finally:
        for child, terminal, _ in children:
            os.close(terminal)
            if child not in reaped:
                os.kill(child, 9)
                os.waitpid(child, 0)


def workspace_panes(session, directory, expected_commands=None):
    deadline = time.monotonic() + 10
    while True:
        output = run_tmux(
            "list-panes", "-s", "-t", f"={session}",
            "-F", "#{window_name}\t#{pane_id}",
        ).stdout.decode().splitlines()
        panes = dict(line.split("\t", 1) for line in output)
        if len(output) == 4:
            break
        assert len(output) < 4 and time.monotonic() < deadline, output
        time.sleep(0.01)
    assert set(panes) == {"editor", "shell", "git", "containers"}, output
    expected_commands = expected_commands or {name: name for name in panes}
    deadline = time.monotonic() + 10
    for name, pane in panes.items():
        record = state / pane
        while not record.exists():
            assert time.monotonic() < deadline, ("window command did not start", name)
            time.sleep(0.05)
        assert record.read_bytes() == expected_commands[name].encode() + b"\0" + os.fsencode(directory.resolve()) + b"\0"
    return panes


try:
    directories = [
        root / "first" / "project",
        root / "second" / "project",
        root / "project space 'quote';#(touch unwanted)#{session_name} end}",
        root / "project ending in newline\n",
    ]
    sessions = []
    for directory in directories:
        directory.mkdir(parents=True)
        session = attach(directory)
        panes = workspace_panes(session, directory)
        assert attach(directory) == session
        assert workspace_panes(session, directory) == panes, "reattach recreated windows"
        sessions.append(session)
    assert len(set(sessions)) == len(directories), "distinct directories shared a session"
    assert not (root / "unwanted").exists(), "project directory executed a command"

    link = root / "project-link"
    link.symlink_to(directories[0], target_is_directory=True)
    assert attach(link) == sessions[0], "symlink created a second project session"
    assert attach(directories[0], arguments=[]) == sessions[0], "current directory changed identity"
    assert attach(directories[0], switch_directory=directories[1]) == sessions[1]
    workspace_panes(sessions[1], directories[1])

    missing = root / "missing preferred tools"
    missing.mkdir()
    session = attach(missing, program=os.environ["LMX_PROJECT_FALLBACK_COMMAND"])
    workspace_panes(session, missing, {name: "shell" for name in ("editor", "shell", "git", "containers")})

    failure = root / "failed preferred editor"
    failure.mkdir()
    session = attach(failure, program=os.environ["LMX_PROJECT_FAILURE_COMMAND"])
    workspace_panes(session, failure, {
        "editor": "shell", "shell": "shell", "git": "git", "containers": "containers",
    })

    concurrent = root / "concurrent project"
    concurrent.mkdir()
    attach_pair(concurrent)

    before = run_tmux("list-sessions", "-F", "#{session_name}").stdout
    for arguments, status in [(["one", "two"], 64), ([str(root / "missing-directory")], 1)]:
        result = subprocess.run([command, *arguments], capture_output=True)
        assert result.returncode == status, (arguments, result)
    assert run_tmux("list-sessions", "-F", "#{session_name}").stdout == before
finally:
    run_tmux("kill-server", check=False)
