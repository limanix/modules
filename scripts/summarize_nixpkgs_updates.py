"""Compare the updated Nixpkgs lock in the CI checkout with its committed pin."""

import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path


NIXPKGS_URL = "https://github.com/NixOS/nixpkgs"


def read_pin(content: str) -> dict:
    lock = json.loads(content)
    root = lock["nodes"][lock["root"]]
    node = lock["nodes"][root["inputs"]["nixpkgs"]]
    pin = dict(node["locked"])
    pin["ref"] = node["original"]["ref"]
    return pin


def table_row(label: str, pin: dict) -> str:
    revision = pin["rev"]
    commit = f"[`{revision[:12]}`]({NIXPKGS_URL}/commit/{revision})"
    date = "—"
    timestamp = pin.get("lastModified")
    if timestamp is not None:
        date = datetime.fromtimestamp(timestamp, timezone.utc).strftime("%Y-%m-%d")
    return f"| {label} | `{pin['ref']}` | {commit} | {date} |"


def main() -> None:
    body = """### ⚪ Check unavailable

Could not determine whether an update is available.
See the steps in this job for details, then rerun the job."""

    if os.environ.get("UPDATE_OUTCOME") == "success":
        try:
            committed_lock = subprocess.check_output(["git", "show", "HEAD:flake.lock"], text=True)
            pinned = read_pin(committed_lock)
            available = read_pin(Path("flake.lock").read_text())
            changed = any(pinned[key] != available[key] for key in ("rev", "narHash", "ref"))

            if changed:
                status = "🟡 Update available"
                details = """To update the base pin locally:

```console
task --yes nixpkgs/update
```"""
                if pinned["rev"] != available["rev"]:
                    compare = f"{NIXPKGS_URL}/compare/{pinned['rev']}...{available['rev']}"
                    details = f"[Review the upstream changes]({compare})\n\n{details}"
            else:
                status = "🟢 Up to date"
                details = "The pinned revision and content hash match the selected branch at check time."

            body = f"""### {status}

| Source | Branch | Commit | Commit date (UTC) |
| --- | --- | --- | --- |
{table_row("Pinned in this PR", pinned)}
{table_row("Available at check time", available)}

{details}

No changes are committed or pushed."""
        except (
            OSError, subprocess.CalledProcessError,
            ValueError, KeyError, TypeError, OverflowError,
        ) as error:
            print(f"Unable to read Nixpkgs update results: {error}")

    report = f"## Nixpkgs updates\n\n{body}\n\nInformational only; this check does not block merging.\n"
    print(report)
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as output:
            output.write(report)


if __name__ == "__main__":
    main()
