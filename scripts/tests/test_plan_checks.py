"""Exercise module selection against isolated Git histories."""

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "plan_checks.py"


class PlanChecksTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.git("-c", "init.templateDir=", "init", "--quiet")

    def git(self, *arguments):
        return subprocess.check_output(
            ["git", "-c", "core.hooksPath=/dev/null", *arguments],
            cwd=self.root, stderr=subprocess.PIPE,
        ).decode().strip()

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
            "-c", "user.name=Check fixture", "-c", "user.email=fixture@example.invalid",
            "commit", "--quiet", "--message=fixture",
        )
        return self.git("rev-parse", "HEAD")

    def invoke(self, *arguments):
        return subprocess.run(
            [sys.executable, str(SCRIPT), *arguments],
            cwd=self.root, capture_output=True, text=True, check=False,
        )

    def diff(self, base):
        result = self.invoke("--base", base, "--head", "HEAD")
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_direct_modules_are_sorted_and_chunked_in_fours(self):
        names = ["zsh", "rust", "python", "go", "git", "helm"]
        for name in names:
            self.module(name)
        base = self.commit()
        for name in names:
            self.write(f"catalog/{name}/check.nix")
        self.commit()
        result = self.diff(base)
        self.assertEqual(result["modules"], sorted(names))
        self.assertEqual(result["chunks"], [
            {"id": "git-go-helm-python", "modules": "git go helm python"},
            {"id": "rust-zsh", "modules": "rust zsh"},
        ])
        self.assertTrue(all(len(chunk["modules"].split()) <= 4 for chunk in result["chunks"]))

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
        (self.root / "catalog/go/helper.nix").rename(self.root / "catalog/rust/helper.nix")
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
            "catalog/_shared/languageSupport.nix", "checks/common.nix",
            "interface.nix", "flake.nix", "flake.lock", "Taskfile.yml",
            ".taskrc.yml", "scripts/run_checks.sh", "scripts/cache_nix_build.sh",
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
        for path in ["guides/index.md", "README.md", "catalog/_shared/README.md",
                     "checks/fixtures/example/README.md", "scripts/build_docs.py"]:
            self.write(path)
        self.commit()
        result = self.diff(base)
        self.assertEqual(result, {
            "modules": [], "chunks": [], "shared_paths": [], "readme_only": False,
        })

    def test_workflow_changes_select_all_modules(self):
        self.module("go")
        self.module("rust")
        base = self.commit()
        self.write(".github/workflows/pr.yml")
        self.commit()
        result = self.diff(base)
        self.assertEqual(result["modules"], ["go", "rust"])
        self.assertEqual(result["shared_paths"], [".github/workflows/pr.yml"])

    def test_readme_rename_does_not_select_either_module(self):
        self.module("go")
        self.module("rust")
        self.write("catalog/go/README.md")
        base = self.commit()
        (self.root / "catalog/go/README.md").rename(self.root / "catalog/rust/README.md")
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
        self.assertEqual(self.diff(base), {
            "modules": [], "chunks": [], "shared_paths": [], "readme_only": True,
        })

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
        self.assertEqual(self.diff(base), {
            "modules": [], "chunks": [], "shared_paths": [], "readme_only": False,
        })

    def test_all_selects_every_current_module(self):
        for name in ["rust", "go", "git", "helm", "python"]:
            self.module(name)
        self.write("catalog/_shared/languageSupport.nix")
        self.commit()
        result = self.invoke("--all")
        self.assertEqual(result.returncode, 0, result.stderr)
        plan = json.loads(result.stdout)
        self.assertEqual(plan["modules"], ["git", "go", "helm", "python", "rust"])
        self.assertEqual(len(plan["chunks"]), 2)
        self.assertEqual(plan["shared_paths"], [])
        self.assertFalse(plan["readme_only"])

    def test_invalid_revision_fails_without_json(self):
        self.module("go")
        self.commit()
        result = self.invoke("--base", "missing-revision", "--head", "HEAD")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("plan-checks:", result.stderr)

    def test_cli_requires_one_selection_mode(self):
        for arguments in [(), ("--base", "HEAD"), ("--head", "HEAD"),
                          ("--all", "--base", "HEAD", "--head", "HEAD")]:
            with self.subTest(arguments=arguments):
                result = self.invoke(*arguments)
                self.assertEqual(result.returncode, 2)
                self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
