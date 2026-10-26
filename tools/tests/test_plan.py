import subprocess
from pathlib import Path

import pytest

from harness import plan


def catalog(repository: Path) -> None:
    (repository / "checks").mkdir()
    (repository / "checks/catalog-kinds.nix").write_text('[ "shell" "toolchains" ]\n')
    for name in ("provider", "consumer", "outer", "unrelated"):
        directory = repository / "catalog/shell" / name
        directory.mkdir(parents=True)
        (directory / "default.nix").write_text("{}\n")
    nested = repository / "catalog/shell/consumer/test/nested.nix"
    nested.parent.mkdir()
    nested.write_text('import (../../provider/versions + "/${line}.nix")\n')
    (repository / "catalog/shell/outer/default.nix").write_text("import ../consumer\n")


def test_astronvim_is_selected_for_its_test_only_rust_dependency() -> None:
    assert plan.from_paths(["catalog/toolchains/rust/default.nix"]) == {
        "targets": ["astronvim", "rust"],
        "image": False,
    }


def test_nested_test_references_and_directory_prefixes_select_transitive_consumers(
    tmp_path: Path,
) -> None:
    catalog(tmp_path)
    assert plan.from_paths(["catalog/shell/provider/releases.nix"], repository=tmp_path) == {
        "targets": ["consumer", "outer", "provider"],
        "image": False,
    }


@pytest.mark.parametrize(
    ("changed", "targets", "image"),
    [
        (["README.md"], [], False),
        (["image.nix"], [], True),
        ([".github/workflows/update.yml"], ["common"], False),
        (
            ["catalog/shell/consumer/test/removed.nix", "Taskfile.yml"],
            ["common", "consumer", "outer"],
            True,
        ),
        (
            ["catalog/_shared/removed.nix", "tools/tests/test_plan.py"],
            ["common", "consumer", "outer", "provider", "unrelated"],
            False,
        ),
        (
            ["flake.lock", "tools/harness/release.py"],
            ["common", "consumer", "outer", "provider", "unrelated"],
            True,
        ),
    ],
)
def test_shared_plumbing_and_image_inputs(
    tmp_path: Path, changed: list[str], targets: list[str], image: bool
) -> None:
    catalog(tmp_path)
    assert plan.from_paths(changed, repository=tmp_path) == {"targets": targets, "image": image}


def test_git_renames_include_removed_module_paths(tmp_path: Path) -> None:
    catalog(tmp_path)

    def git(*arguments: str) -> None:
        subprocess.run(["git", *arguments], cwd=tmp_path, check=True, capture_output=True)

    def commit() -> None:
        git("add", ".")
        git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-m", "Test")

    git("init", "--quiet")
    commit()
    (tmp_path / "catalog/shell/provider").rename(tmp_path / "catalog/shell/renamed")
    commit()
    assert plan.plan(repository=tmp_path) == {
        "targets": ["common", "consumer", "outer", "renamed", "unrelated"],
        "image": False,
    }


def test_all_does_not_need_a_git_base(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    catalog(tmp_path)
    plan.outputs(plan.plan(all_targets=True, repository=tmp_path))
    assert capsys.readouterr().out == (
        'targets=["common","consumer","outer","provider","unrelated"]\nimage=true\n'
    )
