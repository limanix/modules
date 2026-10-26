import pytest

from harness import update

FLAKE = '  inputs = {\n    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";\n  };\n'
UNSTABLE = (
    "# The nixos-unstable revision of the catalog.\n"
    'rev = "0123456789abcdef0123456789abcdef01234567"\n'
    'sha256 = "sha256-old="\n'
)


def test_release_from_flake() -> None:
    assert update.nixos_release(FLAKE) == "26.05"


def test_release_requires_a_pinned_channel() -> None:
    with pytest.raises(ValueError, match="does not pin"):
        update.nixos_release('nixpkgs.url = "github:NixOS/nixpkgs/master";')


@pytest.mark.parametrize(("current", "following"), [("26.05", "26.11"), ("26.11", "27.05")])
def test_next_release(current: str, following: str) -> None:
    assert update.next_release(current) == following


def test_next_release_rejects_other_months() -> None:
    with pytest.raises(ValueError, match=r"Unexpected NixOS release 26\.07"):
        update.next_release("26.07")


def test_locked_nixpkgs_reads_revision_and_utc_day() -> None:
    lock = '{"nodes": {"nixpkgs": {"locked": {"rev": "abc", "lastModified": 1759536000}}}}'
    assert update.locked_nixpkgs(lock) == ("abc", "20251004")


def test_unstable_revision() -> None:
    assert update.unstable_revision(UNSTABLE) == "0123456789abcdef0123456789abcdef01234567"
    assert update.unstable_revision("rev = 'x'\n") == ""


def test_moved_unstable_rewrites_only_the_pinned_lines() -> None:
    moved = update.moved_unstable(UNSTABLE, "f" * 40, "sha256-new=")
    assert moved == (
        "# The nixos-unstable revision of the catalog.\n"
        f'rev = "{"f" * 40}"\n'
        'sha256 = "sha256-new="\n'
    )
