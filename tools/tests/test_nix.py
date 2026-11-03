from pathlib import Path

import pytest

from harness import nix

FIXTURES = Path(__file__).parent / "fixtures"


def test_primary_error_keeps_the_last_error_block_without_source_lines() -> None:
    diagnostic = nix.primary_error((FIXTURES / "failure.err").read_text())
    assert diagnostic.startswith(
        "       error: A definition for option `lmx.capabilities.theme.name'"
    )
    assert "espresso" in diagnostic
    assert "while evaluating" not in diagnostic
    assert "|" not in diagnostic
    assert "is not of type" in diagnostic


def test_primary_error_is_empty_without_an_error_line() -> None:
    assert nix.primary_error("warning: something\n") == ""


def test_build_plan_with_several_derivations() -> None:
    text = (
        "these 2 derivations will be built:\n"
        "  /nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-one.drv\n"
        "  /nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-two.drv\n"
        "these 3 paths will be fetched (1.00 MiB download, 2.00 MiB unpacked):\n"
        "  /nix/store/cccccccccccccccccccccccccccccccc-three\n"
    )
    assert nix.parse_build_plan(text) == [
        "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-one.drv",
        "/nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-two.drv",
    ]


def test_build_plan_with_one_derivation() -> None:
    text = "this derivation will be built:\n  /nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-one.drv\n"
    assert nix.parse_build_plan(text) == ["/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-one.drv"]


def test_build_plan_without_builds() -> None:
    assert nix.parse_build_plan("") == []
    assert (
        nix.parse_build_plan(
            "these 2 paths will be fetched (0.1 MiB download):\n  /nix/store/x-y\n"
        )
        == []
    )


@pytest.mark.parametrize(
    ("text", "message"),
    [
        (
            "this derivation will be built:\n  /nix/store/a-a.drv\n"
            "this derivation will be built:\n",
            "Duplicate build-plan header",
        ),
        ("these derivations will be built:\n", "Unknown build-plan header"),
        ("some text\n  /nix/store/a-a.drv\n", "Unclassified planned derivation"),
        ("these 2 derivations will be built:\n  /nix/store/a-a.drv\n", "Build-plan count mismatch"),
    ],
)
def test_build_plan_rejections(text: str, message: str) -> None:
    with pytest.raises(nix.PlanError, match=message):
        nix.parse_build_plan(text)


def test_literals_escape_nix_syntax() -> None:
    assert nix.string_literal('a"b\\c${d}') == '"a\\"b\\\\c\\${d}"'
    assert nix.list_literal(["a", "b"]) == '[ "a" "b" ]'
    assert nix.list_literal([]) == "[  ]"
    assert nix.path_literal(Path("/tmp/x y")) == '"/tmp/x y"'


def test_supported_versions() -> None:
    nix.require_supported_version("2.35.2")
    with pytest.raises(nix.VersionError, match=r"2\.99\.0 is not supported"):
        nix.require_supported_version("2.99.0")
