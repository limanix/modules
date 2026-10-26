import json
import subprocess
from pathlib import Path

import pytest

from harness import release


def test_next_tag_counts_from_the_highest_release() -> None:
    assert release.next_tag([], []) == "v1"
    assert release.next_tag([], ["v1", "v3", "v2", "v10", "other", "v0"]) == "v11"


def test_no_tag_when_head_is_released(capsys: pytest.CaptureFixture[str]) -> None:
    assert release.next_tag(["v4"], ["v4"]) == ""
    assert "HEAD is released already" in capsys.readouterr().err


@pytest.mark.parametrize(
    ("lock_revision", "unstable_revision", "unstable_hash", "expected"),
    [
        ("old", "old", "old", ""),
        ("new", "old", "old", "v1"),
        ("old", "new", "old", "v1"),
        ("old", "old", "new", "v1"),
    ],
)
def test_tag_checks_input_values_across_the_whole_push(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
    lock_revision: str,
    unstable_revision: str,
    unstable_hash: str,
    expected: str,
) -> None:
    monkeypatch.chdir(tmp_path)

    def git(*arguments: str) -> str:
        return subprocess.run(
            ["git", *arguments], check=True, capture_output=True, text=True
        ).stdout.strip()

    def commit() -> None:
        git("add", ".")
        git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-m", "Test")

    git("init", "--quiet")
    lock = tmp_path / "flake.lock"
    unstable = tmp_path / "catalog/_shared/unstable.toml"
    unstable.parent.mkdir(parents=True)
    lock.write_text('{"nodes":{"nixpkgs":{"locked":{"rev":"old"}}}}\n')
    unstable.write_text('# Update flow\nrev = "old"\nsha256 = "old"\n')
    commit()
    base = git("rev-parse", "HEAD")

    lock.write_text(
        json.dumps({"nodes": {"nixpkgs": {"locked": {"rev": lock_revision}}}}, indent=2) + "\n"
    )
    unstable.write_text(
        f'# Check update flow\nsha256 = "{unstable_hash}"\nrev = "{unstable_revision}"\n'
    )
    commit()
    (tmp_path / "README.md").write_text("A later commit in the same push.\n")
    commit()

    release.tag(base)
    assert capsys.readouterr().out == f"tag={expected}\n"


def test_manifest_matches_the_release_layout(tmp_path: Path) -> None:
    for arch, digest in (("aarch64", "a" * 64), ("x86_64", "b" * 64)):
        (tmp_path / f"limanix-{arch}.qcow2.sha256").write_text(f"{digest}  limanix-{arch}.qcow2\n")
    release.manifest("v7", tmp_path)
    written = (tmp_path / "image.json").read_text()
    downloads = "https://github.com/limanix/modules/releases/download/v7"
    assert json.loads(written) == {
        "version": "v7",
        "systems": {
            "aarch64-linux": {"url": f"{downloads}/limanix-aarch64.qcow2", "sha256": "a" * 64},
            "x86_64-linux": {"url": f"{downloads}/limanix-x86_64.qcow2", "sha256": "b" * 64},
        },
    }


def test_failed_build_preserves_nix_diagnostic(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capfd: pytest.CaptureFixture[str]
) -> None:
    for name, script in (
        ("git", "exit 0\n"),
        ("nix", "printf 'image build failed\\n' >&2\nexit 1\n"),
    ):
        executable = tmp_path / name
        executable.write_text(f"#!/bin/sh\n{script}")
        executable.chmod(0o755)
    monkeypatch.setenv("PATH", str(tmp_path))
    with pytest.raises(subprocess.CalledProcessError):
        release.build("aarch64", tmp_path / "dist")
    assert "image build failed" in capfd.readouterr().err
    assert not (tmp_path / "dist").exists()
