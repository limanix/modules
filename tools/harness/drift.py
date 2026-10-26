import json
import subprocess
import sys
from typing import Any

from harness import REPOSITORY
from harness.nix import FLAGS

TITLE = "Catalog drift"
REPORT = REPOSITORY / "tools" / "drift.nix"


def evaluate() -> dict[str, Any]:
    completed = subprocess.run(
        ["nix", "eval", *FLAGS, "--json", "--impure", "--file", str(REPORT)],
        capture_output=True,
        text=True,
        check=True,
    )
    return dict(json.loads(completed.stdout))


def markdown(report: dict[str, Any]) -> str:
    base = report["base"]
    revisions = (
        f"Base: `{base['rev'][:7]}` ({base['ref']}). nixos-unstable: `{report['unstable'][:7]}`."
    )
    findings = report["findings"]
    if not findings:
        lines = ["The catalog's lines match their sources.", "", revisions]
    else:
        lines = [
            "Lines that differ from their sources by the rule in "
            "[Release maps](catalog/README.md#release-maps).",
            "Edit the module's `releases.nix`, its `module.toml` and README, "
            "then let CI check the change.",
            "",
            revisions,
            "",
            "| Module | Line | Finding |",
            "| -- | -- | -- |",
        ]
        lines += [f"| {item['name']} | {item['line']} | {item['text']} |" for item in findings]
    return "\n".join(lines) + "\n"


def gh(arguments: list[str]) -> str:
    completed = subprocess.run(["gh", *arguments], capture_output=True, text=True, check=True)
    return completed.stdout.strip()


def open_issue(repository: str) -> str:
    return gh(
        [
            "issue",
            "list",
            "--repo",
            repository,
            "--state",
            "open",
            "--json",
            "number,title",
            "--jq",
            f'map(select(.title == "{TITLE}")) | first | .number // empty',
        ]
    )


def report(repository: str) -> None:
    evaluated = evaluate()
    findings = len(evaluated["findings"])
    body = markdown(evaluated)
    number = open_issue(repository)
    if findings:
        if number:
            gh(["issue", "edit", number, "--repo", repository, "--body", body])
        else:
            gh(["issue", "create", "--repo", repository, "--title", TITLE, "--body", body])
    elif number:
        gh(["issue", "close", number, "--repo", repository, "--comment", body])
    print(f"Catalog drift: {findings} finding(s)", file=sys.stderr)
