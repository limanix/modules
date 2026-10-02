#!/usr/bin/env python3
"""Exercise AstroNvim's real exit autosave and cross-process session restore.

Use an isolated HOME. Verify the upstream autosave callback, session snapshots,
restored buffers and cursors, and a second automatic save after restoration.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time


def window_leaves(node):
    if node[0] == "leaf":
        return [node[1]]
    return [leaf for child in node[1] for leaf in window_leaves(child)]


def check_snapshot(path, project, expected):
    data = json.loads(path.read_text())
    assert data["global"]["cwd"] == str(project), data["global"]
    assert len(data["tabs"]) == 1, data["tabs"]
    assert {Path(buf["name"]).name for buf in data["buffers"]} == set(expected), data["buffers"]
    leaves = window_leaves(data["tabs"][0]["wins"])
    actual = {Path(win["bufname"]).name: win["cursor"] for win in leaves}
    assert actual == expected and len(leaves) == 2, actual
    assert isinstance(data["global"]["options"], dict), data["global"]


LUA = r'''
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      local passed, failure = pcall(function()
        assert(vim.v.vim_did_enter == 1, "session check ran before VimEnter")
        assert(vim.g.colors_name == "catppuccin-mocha", "Mocha did not load")
        local found = false
        for _, hook in ipairs(vim.api.nvim_get_autocmds({ event = "VimLeavePre" })) do
          if hook.group_name == "resession_auto_save" then
            found = true
            vim.api.nvim_del_autocmd(hook.id)
            vim.api.nvim_create_autocmd("VimLeavePre", {
              group = hook.group,
              pattern = hook.pattern,
              once = hook.once,
              callback = function(args)
                -- Run the original callback. Record its result because Neovim
                -- can return zero and lose stderr after an exit-hook failure.
                local saved, save_failure = pcall(hook.callback, args)
                local config = package.loaded["resession.config"]
                vim.fn.writefile({ vim.json.encode({
                  passed = saved,
                  failure = saved and "" or tostring(save_failure),
                  eventignore = vim.o.eventignore,
                  options_ready = config ~= nil and type(config.options) == "table",
                }) }, EXIT_SENTINEL)
                if not saved then
                  vim.o.eventignore = ""
                  vim.api.nvim_err_writeln(tostring(save_failure))
                end
              end,
            })
          end
        end
        assert(found, "AstroNvim's exit autosave hook is absent")
        SCENARIO
        assert(vim.v.errmsg == "", vim.v.errmsg)
        vim.fn.writefile({ "entered" }, ENTER_SENTINEL)
      end)
      if not passed then
        vim.api.nvim_err_writeln(tostring(failure))
        vim.cmd("cquit 1")
      else
        vim.cmd("qa!")
      end
    end)
  end,
})
'''

SAVE = r'''
        assert(require("astrocore.buffer").is_valid_session(), "invalid project buffer")
        vim.api.nvim_win_set_cursor(0, { 2, 6 })
        vim.cmd("vsplit second.lua")
        vim.api.nvim_win_set_cursor(0, { 3, 4 })
        assert(#vim.api.nvim_tabpage_list_wins(0) == 2, "project split is absent")
'''

RESTORE = r'''
        require("resession").load("Last Session", { reset = true })
        assert(vim.fn.getcwd() == PROJECT, "session did not restore project cwd")
        local cursors, windows = {}, {}
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)), ":t")
          windows[file] = win
          cursors[file] = vim.api.nvim_win_get_cursor(win)
        end
        assert(#vim.api.nvim_tabpage_list_wins(0) == 2, "restored window count differs")
        assert(vim.deep_equal(cursors, EXPECTED), vim.inspect(cursors))
        assert(type(require("resession.config").options) == "table", "Resession options are unset")
        MUTATION
'''


def run(args):
    start = time.monotonic()
    fixture = Path(tempfile.mkdtemp(prefix="limanix-session-regression-", dir=args.fixture_parent)).resolve()
    project = fixture / "project"
    other = fixture / "other"
    env = os.environ.copy()
    for key, child in {
        "HOME": "home", "XDG_CONFIG_HOME": "config", "XDG_DATA_HOME": "data",
        "XDG_STATE_HOME": "state", "XDG_CACHE_HOME": "cache",
    }.items():
        directory = fixture / child
        directory.mkdir()
        env[key] = str(directory)
    env["TERM"] = "xterm-256color"
    project.mkdir()
    other.mkdir()
    (project / "first.lua").write_text("local first = 1\nlocal second = 2\nreturn first + second\n")
    (project / "second.lua").write_text("local example = {}\nexample.value = 7\nreturn example\n")
    initial = {"first.lua": [2, 6], "second.lua": [3, 4]}
    changed = {"first.lua": [3, 7], "second.lua": [3, 4]}
    session = Path(env["XDG_DATA_HOME"]) / "nvim/session/Last Session.json"
    cwd_session = Path(env["XDG_DATA_HOME"]) / "nvim/dirsession" / (str(project).replace("/", "_").replace(":", "_") + ".json")
    stages = []
    for name, scenario, cwd, expected in [
        ("save", SAVE, project, initial),
        ("resume-update", RESTORE.replace("MUTATION", 'vim.api.nvim_win_set_cursor(windows["first.lua"], { 3, 7 })'), other, changed),
        ("resume-updated", RESTORE.replace("MUTATION", ""), other, changed),
    ]:
        entry = fixture / (name + ".entered")
        sentinel = fixture / (name + ".exit.json")
        expectations = initial if name == "resume-update" else changed
        declarations = (
            "local EXIT_SENTINEL = " + json.dumps(str(sentinel)) + "\n"
            "local ENTER_SENTINEL = " + json.dumps(str(entry)) + "\n"
            "local PROJECT = " + json.dumps(str(project)) + "\n"
            "local EXPECTED = vim.json.decode(" + json.dumps(json.dumps(expectations)) + ")\n"
        )
        script = fixture / (name + ".lua")
        script.write_text(declarations + LUA.replace("SCENARIO", scenario))
        command = [args.editor, "--headless"]
        if name == "save":
            command.append("first.lua")
        command += ["-c", "luafile " + str(script)]
        stage_start = time.monotonic()
        result = subprocess.run(command, cwd=cwd, env=env, capture_output=True, text=True, timeout=45)
        log = fixture / (name + ".log")
        log.write_text(result.stdout + result.stderr)
        assert result.returncode == 0, (name, result.returncode, log.read_text())
        assert not re.search(r"Error in|Error detected|Error executing|E[0-9]+:", log.read_text()), (name, log.read_text())
        assert entry.exists(), (name, "VimEnter assertions did not finish")
        assert sentinel.exists(), (name, "exit autosave callback did not finish")
        exit_report = json.loads(sentinel.read_text())
        assert exit_report["passed"] and exit_report["options_ready"], (name, exit_report)
        assert exit_report["eventignore"] == "", (name, exit_report)
        check_snapshot(session, project, expected)
        check_snapshot(cwd_session, project, expected)
        stages.append({"name": name, "passed": True, "seconds": round(time.monotonic() - stage_start, 3), "log": str(log)})
    return {
        "passed": True, "fixture": str(fixture),
        "seconds": round(time.monotonic() - start, 3), "stages": stages,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--editor", default="nvim")
    parser.add_argument("--fixture-parent", default="/tmp")
    parser.add_argument("--report")
    arguments = parser.parse_args()
    try:
        report = run(arguments)
    except (AssertionError, subprocess.TimeoutExpired) as failure:
        report = {"passed": False, "failure": str(failure)}
    output = json.dumps(report, indent=2)
    print(output)
    if arguments.report:
        Path(arguments.report).write_text(output + "\n")
    raise SystemExit(0 if report["passed"] else 1)
