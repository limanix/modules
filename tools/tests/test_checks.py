import pytest

from harness import checks


def test_request_with_module_names_split_on_whitespace() -> None:
    request = checks.parse_request(["module", "eval", "go docker", "python"])
    assert request == checks.Request("module", "eval", ("go", "docker", "python"))


def test_request_without_modules() -> None:
    assert checks.parse_request(["shared", "check"]) == checks.Request("shared", "check", ())


@pytest.mark.parametrize(
    ("arguments", "message"),
    [
        (["module"], "Usage: harness check"),
        (["nope", "check"], "Unknown suite: nope"),
        (["module", "nope"], "Unknown phase: nope"),
        (["common", "eval"], "The common suite runs shared and platform eval/run together"),
        (["module", "check", "Go"], "Invalid module name: Go"),
        (["module", "check", "a-"], "Invalid module name: a-"),
        (["module", "check", "a" * 64], "Invalid module name"),
        (["module", "check", "pins"], "Reserved module name: pins"),
        (["shared", "check", "go"], "Only the module suite accepts module names"),
    ],
)
def test_request_rejections(arguments: list[str], message: str) -> None:
    with pytest.raises(checks.UsageError, match=message):
        checks.parse_request(arguments)


def test_build_limits_defaults() -> None:
    assert checks.build_limits({}) == checks.Limits(1, 0)


def test_build_limits_accept_the_documented_range() -> None:
    assert checks.build_limits({"NIX_CHECK_JOBS": "64", "NIX_BUILD_CORES": "64"}) == checks.Limits(
        64, 64
    )


@pytest.mark.parametrize(
    ("environment", "message"),
    [
        ({"NIX_CHECK_JOBS": "0"}, "NIX_CHECK_JOBS must be between 1 and 64"),
        ({"NIX_CHECK_JOBS": "65"}, "NIX_CHECK_JOBS must be between 1 and 64"),
        ({"NIX_CHECK_JOBS": "x"}, "NIX_CHECK_JOBS must be between 1 and 64"),
        ({"NIX_BUILD_CORES": "65"}, "NIX_BUILD_CORES must be between 0 and 64"),
        ({"NIX_BUILD_CORES": "-1"}, "NIX_BUILD_CORES must be between 0 and 64"),
    ],
)
def test_build_limits_rejections(environment: dict[str, str], message: str) -> None:
    with pytest.raises(checks.UsageError, match=message):
        checks.build_limits(environment)
