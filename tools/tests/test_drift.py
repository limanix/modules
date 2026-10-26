from typing import Any

import pytest

from harness import drift

REPORT = {
    "base": {"rev": "0d9e9b83abcdef", "ref": "nixos-26.05"},
    "unstable": "abcdef1234567",
    "findings": [],
}
FINDING = {"name": "go", "line": "1.25", "text": "Freeze it on a snapshot"}


def test_markdown_identifies_revisions_and_findings() -> None:
    assert "The catalog's lines match their sources." in drift.markdown(REPORT)
    rendered = drift.markdown({**REPORT, "findings": [FINDING]})
    assert "Base: `0d9e9b8` (nixos-26.05). nixos-unstable: `abcdef1`." in rendered
    assert "| go | 1.25 | Freeze it on a snapshot |" in rendered


@pytest.mark.parametrize(
    ("findings", "number"), [(True, None), (True, 7), (False, 7), (False, None)]
)
def test_report_creates_updates_or_closes_only_its_issue(
    findings: bool, number: int | None, monkeypatch: pytest.MonkeyPatch
) -> None:
    evaluated = {**REPORT, "findings": [FINDING] if findings else []}
    calls: list[tuple[str, str, dict[str, str] | None]] = []

    def github(method: str, path: str, body: dict[str, str] | None = None) -> Any:
        if method == "GET":
            if path.endswith("page=1"):
                return [{"title": drift.TITLE, "number": 2, "pull_request": {}}] * 100
            return [{"title": drift.TITLE, "number": number}] if number else []
        calls.append((method, path, body))
        return {}

    monkeypatch.setattr(drift, "evaluate", lambda: evaluated)
    monkeypatch.setattr(drift, "github", github)
    drift.report("owner/repo")
    body = drift.markdown(evaluated)
    issues = "/repos/owner/repo/issues"
    if findings and number:
        assert calls == [("PATCH", f"{issues}/7", {"body": body})]
    elif findings:
        assert calls == [("POST", issues, {"title": drift.TITLE, "body": body})]
    elif number:
        assert calls == [
            ("POST", f"{issues}/7/comments", {"body": body}),
            ("PATCH", f"{issues}/7", {"state": "closed"}),
        ]
    else:
        assert not calls
