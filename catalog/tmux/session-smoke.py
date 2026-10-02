import os
import pty
import select
import subprocess
import time

provider = os.environ['LMX_SESSION_COMMAND']
tmux = os.environ['LMX_TMUX']


def run_tmux(*arguments):
    return subprocess.run([tmux, *arguments], capture_output=True, check=True).stdout


def attach(name):
    child, terminal = pty.fork()
    if child == 0:
        os.execv(provider, [provider, name])
    output = bytearray()
    reaped = False
    try:
        deadline = time.monotonic() + 15
        while True:
            clients = subprocess.run(
                [tmux, 'list-clients', '-F', '#{session_id}\t#{session_name}'],
                capture_output=True,
            )
            matches = [
                line.split(b'\t', 1)[0]
                for line in clients.stdout.splitlines()
                if line.partition(b'\t')[2] == name.encode()
            ]
            if matches:
                session = matches[0].decode()
                break
            ready, _, _ = select.select([terminal], [], [], 0.05)
            if ready:
                try:
                    output.extend(os.read(terminal, 65536))
                except OSError:
                    pass
            completed, status = os.waitpid(child, os.WNOHANG)
            if completed:
                reaped = True
                raise AssertionError((name, os.waitstatus_to_exitcode(status), output))
            if time.monotonic() >= deadline:
                raise AssertionError(('session did not attach', name, output))
        run_tmux('detach-client', '-s', session)
        deadline = time.monotonic() + 5
        while True:
            completed, status = os.waitpid(child, os.WNOHANG)
            if completed:
                reaped = True
                assert os.waitstatus_to_exitcode(status) == 0, (name, status)
                return session
            if time.monotonic() >= deadline:
                raise AssertionError(('session did not detach', name))
            time.sleep(0.05)
    finally:
        os.close(terminal)
        if not reaped:
            os.kill(child, 9)
            os.waitpid(child, 0)


try:
    for name in ['work', '--help', 'work;', '#(touch unwanted)#{session_name}#[red]']:
        session = attach(name)
        assert attach(name) == session, ('reattach created another session', name)
    assert not os.path.exists('unwanted'), 'session name executed a command'
    before = run_tmux('list-sessions', '-F', '#{session_name}')
    for arguments in [[], [''], ['one', 'two'], ['project.name'], ['project:name']]:
        result = subprocess.run([provider, *arguments], capture_output=True)
        assert result.returncode == 64, (arguments, result)
        assert result.stderr, ('missing session diagnostic', arguments)
    assert run_tmux('list-sessions', '-F', '#{session_name}') == before
finally:
    subprocess.run([tmux, 'kill-server'], capture_output=True)
