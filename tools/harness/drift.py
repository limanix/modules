import json
import os
import subprocess
import sys
import urllib.request
from typing import Any

from harness import REPOSITORY
from harness.nix import FLAGS

TITLE = "Catalog drift"
REPORT = REPOSITORY / "tools" / "drift.nix"


def evaluate() -> dict[str, Any]:
    completed = subprocess.run(
        ["nix", "eval", *FLAGS, "--json", "--impure", "--file", str(REPORT)],
        stdout=subprocess.PIPE,
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


def github(method: str, path: str, body: dict[str, str] | None = None) -> Any:
    token = os.environ.get("GH_TOKEN")
    if not token:
        raise ValueError("drift needs GH_TOKEN")
    request = urllib.request.Request(
        f"https://api.github.com{path}",
        data=json.dumps(body).encode() if body is not None else None,
        method=method,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "limanix-modules",
            "X-GitHub-Api-Version": "2026-03-10",
        },
    )
    with urllib.request.urlopen(request) as response:
        return json.load(response)


def open_issue(repository: str) -> int | None:
    page = 1
    while True:
        issues = github("GET", f"/repos/{repository}/issues?state=open&per_page=100&page={page}")
        for issue in issues:
            if issue["title"] == TITLE and "pull_request" not in issue:
                return int(issue["number"])
        if len(issues) < 100:
            return None
        page += 1


def report(repository: str) -> None:
    evaluated = evaluate()
    findings = len(evaluated["findings"])
    body = markdown(evaluated)
    number = open_issue(repository)
    issues = f"/repos/{repository}/issues"
    if findings:
        if number:
            github("PATCH", f"{issues}/{number}", {"body": body})
        else:
            github("POST", issues, {"title": TITLE, "body": body})
    elif number:
        github("POST", f"{issues}/{number}/comments", {"body": body})
        github("PATCH", f"{issues}/{number}", {"state": "closed"})
    print(f"Catalog drift: {findings} finding(s)", file=sys.stderr)
