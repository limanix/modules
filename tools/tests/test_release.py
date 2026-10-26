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
