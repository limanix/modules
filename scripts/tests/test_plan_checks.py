"""Exercise module selection against isolated Git histories."""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "plan_checks.py"


class PlanChecksTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.environment = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("GIT_")
        }
        self.environment.update(GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1")
        self.git("-c", "init.templateDir=", "init", "--quiet")

    def git(self, *arguments):
        return (
            subprocess.check_output(
                ["git", "-c", "core.hooksPath=/dev/null", *arguments],
                cwd=self.root,
                env=self.environment,
                stderr=subprocess.PIPE,
            )
            .decode()
            .strip()
        )

    def write(self, path, content="test\n"):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)

    def module(self, name):
        self.write(f"catalog/{name}/module.toml", 'description = "fixture"\n')
        self.write(f"catalog/{name}/default.nix", "{ }\n")

    def commit(self):
        self.git("add", "--all")
        self.git(
            "-c",
            "user.name=Check fixture",
            "-c",
            "user.email=fixture@example.invalid",
            "commit",
            "--quiet",
            "--message=fixture",
        )
        return self.git("rev-parse", "HEAD")

    def invoke(self, *arguments):
        return subprocess.run(
            [sys.executable, str(SCRIPT), *arguments],
            cwd=self.root,
            env=self.environment,
            capture_output=True,
            text=True,
            check=False,
        )

    def diff(self, base):
        result = self.invoke("--base", base, "--head", "HEAD")
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_direct_modules_are_sorted_and_isolated_in_jobs(self):
        names = ["zsh", "rust", "python", "go", "git", "helm"]
        for name in names:
            self.module(name)
        base = self.commit()
        for name in names:
            self.write(f"catalog/{name}/check.nix")
        self.commit()
        result = self.diff(base)
        self.assertEqual(result["modules"], sorted(names))
        self.assertEqual(
            result["chunks"],
            [
                {
                    "id": name,
                    "modules": name,
                    "runtime_profile": "all",
                    "runtime_versions": "",
                }
                for name in sorted(names)
            ],
        )

    def test_module_readme_does_not_select_modules(self):
        self.module("go")
        self.module("rust")
        base = self.commit()
        self.write("catalog/go/README.md")
        self.commit()
        result = self.diff(base)
        self.assertEqual(result["modules"], [])
        self.assertTrue(result["readme_only"])

    def test_rename_selects_both_existing_module_paths(self):
        self.module("go")
        self.module("rust")
        self.write("catalog/go/helper.nix")
        base = self.commit()
        (self.root / "catalog/go/helper.nix").rename(
            self.root / "catalog/rust/helper.nix"
        )
        self.commit()
        self.assertEqual(self.diff(base)["modules"], ["go", "rust"])

    def test_deleted_module_is_not_passed_to_runner(self):
        self.module("go")
        self.module("rust")
        base = self.commit()
        for path in (self.root / "catalog/go").iterdir():
            path.unlink()
        (self.root / "catalog/go").rmdir()
        self.commit()
        self.assertEqual(self.diff(base)["modules"], [])
        self.assertEqual(self.diff(base)["chunks"], [])

    def test_shared_paths_select_all_modules(self):
        self.module("go")
        self.module("rust")
        base = self.commit()
        paths = [
            "catalog/_shared/languageSupport.nix",
            "checks/common.nix",
            "interface.nix",
            "flake.nix",
            "flake.lock",
            "Taskfile.yml",
            ".taskrc.yml",
            "scripts/run_checks.sh",
            "scripts/cache_nix_build.sh",
            "scripts/plan_checks.py",
        ]
        for path in paths:
            self.write(path)
        self.commit()
        result = self.diff(base)
        self.assertEqual(result["modules"], ["go", "rust"])
        self.assertEqual(result["shared_paths"], sorted(paths))

    def test_documentation_does_not_select_modules(self):
        self.module("go")
        base = self.commit()
        for path in [
            "guides/index.md",
            "README.md",
            "catalog/_shared/README.md",
            "checks/fixtures/example/README.md",
            "scripts/build_docs.py",
        ]:
            self.write(path)
        self.commit()
        result = self.diff(base)
        self.assertEqual(
            result,
            {
                "modules": [],
                "chunks": [],
                "shared_paths": [],
                "readme_only": False,
            },
        )

    def test_workflow_changes_select_all_modules(self):
        self.module("go")
        self.module("rust")
        base = self.commit()
        self.write(".github/workflows/pr.yml")
        self.commit()
        result = self.diff(base)
        self.assertEqual(result["modules"], ["go", "rust"])
        self.assertEqual(result["shared_paths"], [".github/workflows/pr.yml"])
        self.assertTrue(
            all(chunk["runtime_profile"] == "pr" for chunk in result["chunks"])
        )

    def test_readme_rename_does_not_select_either_module(self):
        self.module("go")
        self.module("rust")
        self.write("catalog/go/README.md")
        base = self.commit()
        (self.root / "catalog/go/README.md").rename(
            self.root / "catalog/rust/README.md"
        )
        self.commit()
        result = self.diff(base)
        self.assertEqual(result["modules"], [])
        self.assertTrue(result["readme_only"])

    def test_multiple_readmes_have_a_readme_only_plan(self):
        self.module("go")
        base = self.commit()
        for path in ["README.md", "catalog/go/README.md", "catalog/_shared/README.md"]:
            self.write(path)
        self.commit()
        self.assertEqual(
            self.diff(base),
            {
                "modules": [],
                "chunks": [],
                "shared_paths": [],
                "readme_only": True,
            },
        )

    def test_readme_with_module_source_keeps_regular_module_checks(self):
        self.module("go")
        base = self.commit()
        self.write("catalog/go/README.md")
        self.write("catalog/go/check.nix")
        self.commit()
        result = self.diff(base)
        self.assertEqual(result["modules"], ["go"])
        self.assertFalse(result["readme_only"])

    def test_unchanged_history_has_an_empty_plan(self):
        self.module("go")
        base = self.commit()
        self.assertEqual(
            self.diff(base),
            {
                "modules": [],
                "chunks": [],
                "shared_paths": [],
                "readme_only": False,
            },
        )

    def test_all_selects_every_current_module(self):
        for name in ["rust", "go", "git", "helm", "python"]:
            self.module(name)
        self.write("catalog/_shared/languageSupport.nix")
        self.commit()
        result = self.invoke("--all")
        self.assertEqual(result.returncode, 0, result.stderr)
        plan = json.loads(result.stdout)
        self.assertEqual(plan["modules"], ["git", "go", "helm", "python", "rust"])
        self.assertEqual(len(plan["chunks"]), 5)
        self.assertTrue(
            all(
                chunk["runtime_profile"] == "all" and chunk["runtime_versions"] == ""
                for chunk in plan["chunks"]
            )
        )
        self.assertEqual(plan["shared_paths"], [])
        self.assertFalse(plan["readme_only"])

    def test_invalid_revision_fails_without_json(self):
        self.module("go")
        self.commit()
        result = self.invoke("--base", "missing-revision", "--head", "HEAD")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("plan-checks:", result.stderr)

    def test_disposable_git_history_ignores_inherited_git_environment(self):
        poisoned_index = self.root / "inherited-index"
        nested = PlanChecksTests(methodName="runTest")
        try:
            with patch.dict(
                os.environ,
                {
                    "GIT_DIR": str(self.root / "missing.git"),
                    "GIT_WORK_TREE": str(self.root),
                    "GIT_INDEX_FILE": str(poisoned_index),
                    "GIT_CONFIG_COUNT": "1",
                    "GIT_CONFIG_KEY_0": "commit.gpgsign",
                    "GIT_CONFIG_VALUE_0": "true",
                },
            ):
                nested.setUp()
                nested.module("go")
                nested.commit()
                result = nested.invoke("--all")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout)["modules"], ["go"])
            self.assertFalse(poisoned_index.exists())
            self.assertFalse((self.root / "missing.git").exists())
        finally:
            nested.doCleanups()

    def test_sibling_consumers_are_selected_transitively(self):
        for name in ["git", "lazygit", "console", "cozy", "go"]:
            self.module(name)
        self.write(
            "catalog/lazygit/default.nix", "{ imports = [ ../git/default.nix ]; }\n"
        )
        self.write("catalog/console/components.nix", "[ ../lazygit/default.nix ]\n")
        self.write(
            "catalog/cozy/default.nix", "{ imports = [ ../console/default.nix ]; }\n"
        )
        base = self.commit()
        self.write("catalog/git/check.nix")
        self.commit()
        self.assertEqual(
            self.diff(base)["modules"], ["console", "cozy", "git", "lazygit"]
        )
        self.assertTrue(
            all(
                chunk["runtime_profile"] == "all" for chunk in self.diff(base)["chunks"]
            )
        )

    def test_deleted_component_still_selects_its_consumer(self):
        for name in ["git", "console"]:
            self.module(name)
        self.write(
            "catalog/console/default.nix", "{ imports = [ ../git/default.nix ]; }\n"
        )
        base = self.commit()
        for path in (self.root / "catalog/git").iterdir():
            path.unlink()
        (self.root / "catalog/git").rmdir()
        self.commit()
        self.assertEqual(self.diff(base)["modules"], ["console"])

    def test_computed_catalog_path_conservatively_selects_consumer(self):
        for name in ["go", "rust", "astronvim"]:
            self.module(name)
        self.write(
            "catalog/astronvim/tests.nix",
            'import (../. + "/${name}/packages.nix") {}\n',
        )
        base = self.commit()
        self.write("catalog/go/check.nix")
        self.commit()
        self.assertEqual(self.diff(base)["modules"], ["astronvim", "go"])

    def test_shared_runtime_asset_selects_every_module(self):
        for name in ["git", "go"]:
            self.module(name)
        base = self.commit()
        self.write("catalog/_shared/shell-init.sh")
        self.commit()
        self.assertEqual(self.diff(base)["modules"], ["git", "go"])
        self.assertTrue(
            all(
                chunk["runtime_profile"] == "all" for chunk in self.diff(base)["chunks"]
            )
        )

    def test_cli_requires_one_selection_mode(self):
        for arguments in [
            (),
            ("--base", "HEAD"),
            ("--head", "HEAD"),
            ("--all", "--base", "HEAD", "--head", "HEAD"),
        ]:
            with self.subTest(arguments=arguments):
                result = self.invoke(*arguments)
                self.assertEqual(result.returncode, 2)
                self.assertEqual(result.stdout, "")

    def test_invalid_catalog_name_is_not_emitted_as_a_workflow_argument(self):
        self.module('go";touch marker')
        self.commit()
        result = self.invoke("--all")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertIn("invalid catalog module directory", result.stderr)
        self.assertFalse((self.root / "marker").exists())

    def test_changed_historical_line_keeps_current_smoke_and_targets_that_line(self):
        for name in ["go", "console"]:
            self.module(name)
        self.write(
            "catalog/go/module.toml",
            'description = "fixture"\nversions = ["1.26", "1.27"]\n',
        )
        self.write("catalog/go/versions/1.26.nix", "{}\n")
        self.write("catalog/go/versions/1.27.nix", "{}\n")
        self.write(
            "catalog/console/default.nix", "{ imports = [ ../go/default.nix ]; }\n"
        )
        base = self.commit()
        self.write("catalog/go/versions/1.26.nix", "{ changed = true; }\n")
        self.commit()
        chunks = {chunk["modules"]: chunk for chunk in self.diff(base)["chunks"]}
        self.assertEqual(chunks["go"]["runtime_profile"], "pr")
        self.assertEqual(chunks["go"]["runtime_versions"], "1.26")
        self.assertEqual(chunks["console"]["runtime_profile"], "pr")
        self.assertEqual(chunks["console"]["runtime_versions"], "")

    def test_pin_and_metadata_changes_require_complete_module_runtime(self):
        self.module("go")
        self.commit()
        for path in ["catalog/go/releases.nix", "catalog/go/module.toml"]:
            with self.subTest(path=path):
                base = self.git("rev-parse", "HEAD")
                self.write(path, 'description = "changed fixture"\n')
                self.commit()
                chunk = self.diff(base)["chunks"][0]
                self.assertEqual(chunk["runtime_profile"], "all")
                self.assertEqual(chunk["runtime_versions"], "")

    def test_known_unversioned_palette_change_uses_current_runtime(self):
        for name in ["go", "zsh"]:
            self.module(name)
        self.write("catalog/go/module.toml", 'versions = ["1.26", "1.27"]\n')
        self.write(
            "catalog/zsh/default.nix", "builtins.readFile ../_shared/palette.toml\n"
        )
        base = self.commit()
        self.write("catalog/_shared/palette.toml", 'color = "blue"\n')
        self.commit()
        chunks = self.diff(base)["chunks"]
        self.assertEqual(len(chunks), 2)
        self.assertTrue(
            all(
                chunk["runtime_profile"] == "pr" and chunk["runtime_versions"] == ""
                for chunk in chunks
            )
        )

    def test_palette_versioned_unknown_or_shared_consumers_require_all_runtime(self):
        for name in ["go", "zsh"]:
            self.module(name)
        self.write(
            "catalog/zsh/default.nix", "builtins.readFile ../_shared/palette.toml\n"
        )
        self.commit()
        for path, content in [
            ("catalog/zsh/module.toml", 'versions = ["1"]\n'),
            ("catalog/go/default.nix", "builtins.readFile ../_shared/palette.toml\n"),
            ("catalog/_shared/theme.nix", "builtins.readFile ./palette.toml\n"),
        ]:
            with self.subTest(path=path):
                # Test each widening independently of the preceding widening.
                self.write("catalog/zsh/module.toml", 'description = "fixture"\n')
                self.write("catalog/go/default.nix", "{}\n")
                shared = self.root / "catalog/_shared/theme.nix"
                if shared.exists():
                    shared.unlink()
                self.write(path, content)
                base = self.commit()
                self.write("catalog/_shared/palette.toml", content)
                self.commit()
                self.assertTrue(
                    all(
                        chunk["runtime_profile"] == "all"
                        for chunk in self.diff(base)["chunks"]
                    )
                )

    def test_pod_sources_and_transitive_consumers_require_all_runtime(self):
        for name in ["go", "console", "cozy", "k9s"]:
            self.module(name)
        self.write(
            "catalog/console/default.nix", "{ imports = [ ../go/default.nix ]; }\n"
        )
        self.write(
            "catalog/cozy/default.nix", "{ imports = [ ../console/default.nix ]; }\n"
        )
        self.commit()
        for filename in [
            "packages.nix",
            "module.nix",
            "selection.nix",
            "smoke.nix",
            "tests.nix",
            "config.toml",
        ]:
            with self.subTest(filename=filename):
                base = self.git("rev-parse", "HEAD")
                self.write(f"catalog/go/{filename}")
                self.commit()
                chunks = self.diff(base)["chunks"]
                self.assertEqual(
                    [chunk["modules"] for chunk in chunks], ["console", "cozy", "go"]
                )
                self.assertTrue(
                    all(chunk["runtime_profile"] == "all" for chunk in chunks)
                )

    def test_unregistered_version_is_rejected_even_with_changed_pod_sources(self):
        self.module("go")
        self.write("catalog/go/module.toml", 'versions = ["1.27"]\n')
        base = self.commit()
        self.write("catalog/go/packages.nix")
        self.write("catalog/go/versions/1.26.nix", "{}\n")
        self.commit()
        result = self.invoke("--base", base, "--head", "HEAD")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")

    def test_module_guide_keeps_current_runtime_only(self):
        self.module("go")
        base = self.commit()
        self.write("catalog/go/troubleshooting.md")
        self.commit()
        chunk = self.diff(base)["chunks"][0]
        self.assertEqual(chunk["runtime_profile"], "pr")
        self.assertEqual(chunk["runtime_versions"], "")

    def test_changed_undeclared_or_overlong_version_fails_without_matrix(self):
        self.module("go")
        self.write(
            "catalog/go/module.toml", 'description = "fixture"\nversions = ["1.27"]\n'
        )
        base = self.commit()
        for version in ["1.26", "1" * 64]:
            with self.subTest(version=version):
                self.write(f"catalog/go/versions/{version}.nix", "{}\n")
                self.commit()
                result = self.invoke("--base", base, "--head", "HEAD")
                self.assertEqual(result.returncode, 1)
                self.assertEqual(result.stdout, "")
                self.assertFalse((self.root / "marker").exists())
                base = self.git("rev-parse", "HEAD")

    def test_private_version_helpers_require_full_runtime_and_remain_private(self):
        for name in ["go", "console"]:
            self.module(name)
        self.write("catalog/go/module.toml", 'versions = ["1.27"]\n')
        self.write("catalog/go/versions/1.27.nix", "import ./helper.nix\n")
        self.write("catalog/go/versions/helper.nix", "{}\n")
        self.write(
            "catalog/console/default.nix", "{ imports = [ ../go/default.nix ]; }\n"
        )
        self.commit()
        for filename in ["helper.nix", "private/1.27.nix"]:
            with self.subTest(filename=filename):
                base = self.git("rev-parse", "HEAD")
                self.write(f"catalog/go/versions/{filename}", "{ changed = true; }\n")
                self.commit()
                chunks = self.diff(base)["chunks"]
                self.assertEqual(
                    [chunk["modules"] for chunk in chunks], ["console", "go"]
                )
                self.assertTrue(
                    all(
                        chunk["runtime_profile"] == "all"
                        and not chunk["runtime_versions"]
                        for chunk in chunks
                    )
                )

    def test_computed_shared_palette_read_restores_full_runtime(self):
        for name in ["go", "zsh"]:
            self.module(name)
        self.write("catalog/go/module.toml", 'versions = ["1.27"]\n')
        self.write(
            "catalog/zsh/default.nix", "builtins.readFile ../_shared/palette.toml\n"
        )
        for reader in [
            'let filename = "palette" + ".toml"; in builtins.readFile (../_shared + "/${filename}")\n',
            'let shared = ../_shared; in builtins.readFile (shared + "/${filename}")\n',
        ]:
            with self.subTest(reader=reader):
                self.write("catalog/go/default.nix", reader)
                base = self.commit()
                self.write("catalog/_shared/palette.toml", reader)
                self.commit()
                self.assertTrue(
                    all(
                        chunk["runtime_profile"] == "all"
                        for chunk in self.diff(base)["chunks"]
                    )
                )

    def test_unknown_shared_data_helper_disables_palette_shortcut(self):
        self.module("zsh")
        self.write(
            "catalog/zsh/default.nix", "builtins.readFile ../_shared/palette.toml\n"
        )
        self.write("catalog/_shared/data.nix", "file: builtins.readFile (./. + file)\n")
        base = self.commit()
        self.write("catalog/_shared/palette.toml")
        self.commit()
        self.assertEqual(self.diff(base)["chunks"][0]["runtime_profile"], "all")

    def test_removed_undeclared_line_requires_full_remaining_runtime(self):
        self.module("go")
        self.write(
            "catalog/go/module.toml", 'description = "fixture"\nversions = ["1.27"]\n'
        )
        self.write("catalog/go/versions/1.26.nix", "{}\n")
        base = self.commit()
        (self.root / "catalog/go/versions/1.26.nix").unlink()
        self.commit()
        chunk = self.diff(base)["chunks"][0]
        self.assertEqual(chunk["runtime_profile"], "all")
        self.assertEqual(chunk["runtime_versions"], "")


if __name__ == "__main__":
    unittest.main()
