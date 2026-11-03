import json
import os

from terminal import TerminalError, TerminalProcess, TerminalTimeout

script = f'source {os.environ["LMX_INIT"]} && source {os.environ["LMX_CHECK"]} && echo LMX_PROMPT_OK'
command = [*json.loads(os.environ["LMX_SHELL"]), script]

with TerminalProcess(command, env=os.environ, cwd=os.environ["HOME"]) as process:
    try:
        process.until(lambda: b"LMX_PROMPT_OK" in process.output, timeout=60, label="prompt checks")
        status = process.wait(timeout=5)
    except (TerminalError, TerminalTimeout) as error:
        raise AssertionError(str(error)) from error
    output = process.output.decode(errors="replace")
    assert status == 0, (status, output)
