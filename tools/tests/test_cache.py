from pathlib import Path

import pytest

from harness import cache


def test_uri_encoding_keeps_the_order_of_the_runner() -> None:
    assert cache.encode_uri("/a b/c%d#e?f&g+h") == "/a%20b/c%25d%23e%3Ff%26g%2Bh"


def test_hook_skips_without_an_absolute_cache(capsys: pytest.CaptureFixture[str]) -> None:
    assert cache.hook({"OUT_PATHS": "/nix/store/x"}) == 0
    assert "cache path must be absolute" in capsys.readouterr().err


def test_hook_ignores_empty_outputs(tmp_path: Path) -> None:
    assert cache.hook({"NIX_BUILD_CACHE": str(tmp_path / "cache")}) == 0
    assert not (tmp_path / "cache").exists()


def test_hook_skips_relative_outputs(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert cache.hook({"NIX_BUILD_CACHE": str(tmp_path), "OUT_PATHS": "/nix/store/x y"}) == 0
    assert "output path must be absolute" in capsys.readouterr().err


def write_cache(directory: Path, entries: dict[str, str]) -> None:
    (directory / "nar").mkdir()
    for store_hash, nar in entries.items():
        (directory / f"{store_hash}.narinfo").write_text(f"StorePath: x\nURL: nar/{nar}\n")
        (directory / "nar" / nar).write_text("nar")


def test_prune_keeps_live_entries_and_their_nars(tmp_path: Path) -> None:
    write_cache(tmp_path, {"aaaa": "a.nar.zst", "bbbb": "b.nar.zst"})
    (tmp_path / "nar" / "orphan.nar.zst").write_text("nar")
    (tmp_path / ".live").write_text("/nix/store/aaaa-live\n\n/nix/store/cccc-unknown\n")
    cache.prune(tmp_path)
    assert sorted(path.name for path in tmp_path.iterdir()) == ["aaaa.narinfo", "nar"]
    assert [path.name for path in (tmp_path / "nar").iterdir()] == ["a.nar.zst"]


def test_prune_leaves_the_cache_alone_without_a_live_list(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    write_cache(tmp_path, {"aaaa": "a.nar.zst"})
    cache.prune(tmp_path)
    assert (tmp_path / "aaaa.narinfo").exists()
    assert "no live list" in capsys.readouterr().err


def test_prune_leaves_the_cache_alone_with_an_incomplete_live_list(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    write_cache(tmp_path, {"aaaa": "a.nar.zst"})
    (tmp_path / ".live").write_text("/nix/store/bbbb-gone\n*\n")
    cache.prune(tmp_path)
    assert (tmp_path / "aaaa.narinfo").exists()
    assert not (tmp_path / ".live").exists()
    assert "incomplete live list" in capsys.readouterr().err
