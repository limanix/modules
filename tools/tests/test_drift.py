from harness import drift

REPORT = {
    "base": {"rev": "0d9e9b83abcdef", "ref": "nixos-26.05"},
    "unstable": "abcdef1234567",
    "findings": [],
}


def test_markdown_without_findings() -> None:
    assert drift.markdown(REPORT) == (
        "The catalog's lines match their sources.\n"
        "\n"
        "Base: `0d9e9b8` (nixos-26.05). nixos-unstable: `abcdef1`.\n"
    )


def test_markdown_with_findings() -> None:
    report = {
        **REPORT,
        "findings": [
            {"name": "go", "line": "1.25", "text": "No longer in the base: freeze it on a snapshot"}
        ],
    }
    assert drift.markdown(report) == (
        "Lines that differ from their sources by the rule in "
        "[Release maps](catalog/README.md#release-maps).\n"
        "Edit the module's `releases.nix`, its `module.toml` and README, "
        "then let CI check the change.\n"
        "\n"
        "Base: `0d9e9b8` (nixos-26.05). nixos-unstable: `abcdef1`.\n"
        "\n"
        "| Module | Line | Finding |\n"
        "| -- | -- | -- |\n"
        "| go | 1.25 | No longer in the base: freeze it on a snapshot |\n"
    )
