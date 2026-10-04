"""Exercise the selected Cozy workspace with real tools and temporary user state."""

from contextlib import ExitStack
import hashlib
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

from terminal import TerminalProcess


COMMAND = os.environ["LMX_PROJECT_COMMAND"]
TMUX = os.environ["LMX_TMUX"]
SHELL_NAME = Path(os.environ["LMX_SHELL"]).name
WINDOWS = {"editor", "shell", "git", "containers"}
ENVIRONMENT = dict(os.environ)
for variable in ("TMUX", "TMUX_PANE", "NVIM", "GIT_DIR", "GIT_WORK_TREE"):
    ENVIRONMENT.pop(variable, None)


def tmux(*arguments, check=True, timeout=10):
    return subprocess.run(
        [TMUX, *arguments],
        env=ENVIRONMENT,
        stdin=subprocess.DEVNULL,
        capture_output=True,
        check=check,
        timeout=timeout,
    )


def session_name(directory):
    physical = directory.resolve()
    name = re.sub(r"[^a-zA-Z0-9_-]", "-", physical.name)[:24] or "root"
    identity = hashlib.sha256(os.fsencode(physical)).hexdigest()[:16]
    return f"project-{name}-{identity}"


def clients(session):
    result = tmux("list-clients", "-F", "#{session_name}", check=False)
    return result.stdout.splitlines().count(session.encode())


def panes(session):
    result = tmux(
        "list-panes", "-s", "-t", "=" + session,
        "-F", "#{window_name}\t#{window_id}\t#{pane_id}", check=False,
    )
    if result.returncode:
        return {}
    records = [line.decode().split("\t") for line in result.stdout.splitlines()]
    assert all(len(record) == 3 for record in records), records
    assert len({record[0] for record in records}) == len(records), records
    return {name: (window, pane) for name, window, pane in records}


def pane_value(pane, expression):
    output = tmux("display-message", "-p", "-t", pane, expression).stdout
    assert output.endswith(b"\n"), output
    # Remove the protocol newline only; project paths may end with a newline.
    return output[:-1]


def workspace_state(session, directory):
    records = panes(session)
    assert set(records) == WINDOWS, records
    expected = os.fsencode(directory.resolve())
    for name, (_, pane) in records.items():
        actual = pane_value(pane, "#{pane_current_path}")
        assert actual == expected, (name, actual, expected)
    return records


def attach(directory, *, arguments=None, cwd=None, inspect=None):
    session = session_name(directory)
    arguments = [str(directory)] if arguments is None else arguments
    with TerminalProcess([COMMAND, *arguments], env=ENVIRONMENT, cwd=cwd) as terminal:
        terminal.until(lambda: clients(session) == 1, label=f"attach {session}")
        terminal.until(lambda: set(panes(session)) == WINDOWS, label="four project windows")
        state = workspace_state(session, directory)
        if inspect is not None:
            inspect(terminal, session, state)
            assert workspace_state(session, directory) == state, "application exit changed the workspace"
        tmux("detach-client", "-s", "=" + session)
        assert terminal.wait() == 0, terminal.diagnostic()
    return state


def pane_command(pane):
    return pane_value(pane, "#{pane_current_command}").decode()


def shell_running(pane):
    return pane_command(pane).strip(".").removesuffix("-wrapped") == SHELL_NAME


def editor_exit(terminal, session, state, *, fail):
    pane = state["editor"][1]
    tmux("select-window", "-t", state["editor"][0])
    terminal.until(lambda: "nvim" in pane_command(pane), label="real configured editor")
    tmux("send-keys", "-t", pane, "Escape", ":cquit" if fail else ":qa!", "Enter")
    terminal.until(lambda: shell_running(pane), label="editor window shell fallback")
    if fail:
        output = tmux("capture-pane", "-p", "-t", pane).stdout
        assert b"Workspace editor exited with status 1; opening a shell." in output, output
    assert panes(session) == state, "application exit replaced project windows"


def other_app_exits(terminal, state):
    for name in ("git", "containers"):
        window, pane = state[name]
        tmux("select-window", "-t", window)
        terminal.until(
            lambda: shell_running(pane) or "lazy" in pane_command(pane),
            label=f"real {name} window application",
        )
        if not shell_running(pane):
            # The actual tools may show a connection/repository error before exit.
            tmux("send-keys", "-t", pane, "C-c")
        terminal.until(lambda: shell_running(pane), label=f"{name} window shell fallback")


def switch_client(source, target, expected):
    session = session_name(source)
    target_session = session_name(target)
    with TerminalProcess([COMMAND, str(source)], env=ENVIRONMENT) as terminal:
        terminal.until(lambda: clients(session) == 1, label="attach before client switch")
        state = workspace_state(session, source)
        tmux("select-window", "-t", state["shell"][0])
        terminal.until(lambda: shell_running(state["shell"][1]), label="project shell")
        tmux("send-keys", "-t", state["shell"][1], "-l", shlex.join([COMMAND, str(target)]))
        tmux("send-keys", "-t", state["shell"][1], "Enter")
        terminal.until(lambda: clients(target_session) == 1, label="switch current client")
        assert clients(session) == 0, "source session retained the switched client"
        assert workspace_state(target_session, target) == expected, "switch recreated windows"
        tmux("detach-client", "-s", "=" + target_session)
        assert terminal.wait() == 0, terminal.diagnostic()


def concurrent_attach(directory):
    session = session_name(directory)
    with ExitStack() as stack:
        terminals = [
            stack.enter_context(TerminalProcess([COMMAND, str(directory)], env=ENVIRONMENT))
            for _ in range(2)
        ]

        def both_attached():
            for terminal in terminals:
                terminal.drain()
                assert terminal.poll() is None, terminal.diagnostic()
            return clients(session) == 2

        terminals[0].until(both_attached, label="concurrent project callers")
        terminals[0].until(lambda: set(panes(session)) == WINDOWS, label="concurrent project windows")
        workspace_state(session, directory)
        tmux("detach-client", "-s", "=" + session)
        for terminal in terminals:
            assert terminal.wait() == 0, terminal.diagnostic()


with tempfile.TemporaryDirectory(prefix="cozy-workspace-") as fixture:
    root = Path(fixture)
    projects = [
        root / "first" / "same project",
        root / "second" / "same project",
        root / "project space 'quote';$(touch unwanted)#(touch unwanted)#{session_name} end}",
        root / "project ending in newline\n",
    ]
    snapshots = []
    try:
        for index, project in enumerate(projects):
            project.mkdir(parents=True)

            def inspect(terminal, session, state):
                if index < 2:
                    editor_exit(terminal, session, state, fail=index == 1)
                    other_app_exits(terminal, state)

            state = attach(project, inspect=inspect)
            assert attach(project) == state, "reattachment replaced project windows"
            snapshots.append(state)
        assert len({session_name(project) for project in projects}) == len(projects)
        assert not any(root.rglob("unwanted")), "project path executed a command"
        assert not (Path.cwd() / "unwanted").exists(), "project path executed a command"

        alias = root / "project alias"
        alias.symlink_to(projects[0], target_is_directory=True)
        assert attach(alias) == snapshots[0], "symlink alias replaced the physical workspace"
        assert attach(projects[0], arguments=[], cwd=projects[0]) == snapshots[0]
        switch_client(projects[0], projects[1], snapshots[1])
        assert len(tmux("list-sessions", "-F", "#{session_name}").stdout.splitlines()) == len(projects)

        concurrent = root / "concurrent project"
        concurrent.mkdir()
        concurrent_attach(concurrent)

        before = tmux("list-sessions", "-F", "#{session_name}").stdout
        for arguments, status, message in [
            (["one", "two"], 64, b"Usage: tmux-project [directory]"),
            ([str(root / "missing directory")], 1, b"missing directory"),
        ]:
            result = subprocess.run(
                [COMMAND, *arguments], env=ENVIRONMENT, stdin=subprocess.DEVNULL,
                capture_output=True, timeout=10,
            )
            assert result.returncode == status, (arguments, result)
            assert message in result.stderr, (arguments, result.stderr)
        assert tmux("list-sessions", "-F", "#{session_name}").stdout == before
    finally:
        tmux("kill-server", check=False, timeout=5)
