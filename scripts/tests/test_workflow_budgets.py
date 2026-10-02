"""Check CPU allocation, performance targets, cache scope and hang guards."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

import test_plan_checks
import test_run_checks

WORKFLOW = (
    Path(__file__).resolve().parents[2] / ".github" / "workflows" / "nix-tests.yml"
)
WORKFLOWS = WORKFLOW.parent


def cache_configuration(
    module: str, pins: str, architecture: str = "ARM64"
) -> tuple[str, list[str]]:
    source = WORKFLOW.read_text()
    primary = re.search(r"(?m)^          key: (nix-v3-.+)$", source).group(1)
    block = re.search(
        r"(?m)^          restore-keys: \|\n((?:            .+\n)+)", source
    ).group(1)
    replacements = {
        "${{ runner.os }}": "Linux",
        "${{ runner.arch }}": architecture,
        "${{ inputs.cache-id }}": module,
        "${{ hashFiles('flake.lock', 'catalog/**/releases.nix') }}": pins,
        "${{ github.sha }}": "c" * 40,
        "${{ github.run_attempt }}": "1",
    }

    def render(value):
        for expression, replacement in replacements.items():
            value = value.replace(expression, replacement)
        if "${{" in value:
            raise AssertionError(f"unresolved cache expression: {value}")
        return value

    return render(primary), [render(line.strip()) for line in block.splitlines()]


def restored_cache(
    primary: str, prefixes: list[str], newest_first: list[str]
) -> str | None:
    """Model documented ordered prefix lookup with the newest match first."""
    for prefix in [primary, *prefixes]:
        exact = next((key for key in newest_first if key == prefix), None)
        if exact is not None:
            return exact
        match = next((key for key in newest_first if key.startswith(prefix)), None)
        if match is not None:
            return match
    return None


def check_jobs(task: str) -> int:
    """Resolve the small task conditional used by the native workflow."""
    matches = re.findall(r"NIX_CHECK_JOBS=(\$\{\{.*?\}\}|[0-9]+)", WORKFLOW.read_text())
    if len(matches) != 1:
        raise AssertionError("native workflow must declare one NIX_CHECK_JOBS value")
    value = matches[0]
    if value.isdecimal():
        return int(value)
    conditional = re.fullmatch(
        r"\$\{\{\s*inputs\.task\s*==\s*'([^']+)'\s*"
        r"&&\s*([0-9]+)\s*\|\|\s*([0-9]+)\s*\}\}",
        value,
    )
    if conditional is None:
        raise AssertionError("unsupported native workflow jobs expression")
    selected, matched, otherwise = conditional.groups()
    return int(matched if task == selected else otherwise)


class WorkflowBudgetTests(unittest.TestCase):
    def run_native_fixture(self, task: str, *arguments: str) -> dict:
        fixture = test_run_checks.RunChecksTests(
            "test_common_requires_the_expected_diagnostic"
        )
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        fixture.environment.pop("NIX_BUILD_CORES", None)
        fixture.environment.pop("NIX_BUILD_CACHE", None)
        fixture.stub("id", "print('501')")
        fixture.stub(
            "nix-store",
            "import json, pathlib, sys\n"
            f"pathlib.Path({str(fixture.root / 'realise.json')!r}).write_text("
            "json.dumps(sys.argv[1:]))\nprint('Built shared fixture')",
        )
        fixture.stub(
            "nix-instantiate",
            "import json, pathlib, sys\n"
            f"pathlib.Path({str(fixture.root / 'instantiate.json')!r}).write_text("
            "json.dumps(sys.argv[1:]))\nprint('/nix/store/shared-fixture.drv')",
        )
        fixture.stub(
            "timeout",
            "import json, os, pathlib, sys\n"
            f"pathlib.Path({str(fixture.root / 'timeout.json')!r}).write_text("
            "json.dumps(sys.argv[1:]))\n"
            "os.execvp(sys.argv[3], sys.argv[3:])",
        )
        limits = re.findall(r"NIX_CHECK_TIMEOUT=([0-9]+)", WORKFLOW.read_text())
        self.assertEqual(limits, ["1800"])
        result = fixture.invoke(
            *arguments,
            NIX_CHECK_JOBS=str(check_jobs(task)),
            NIX_CHECK_BATCH_SIZE="1",
            NIX_CHECK_TIMEOUT=limits[0],
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return {
            name: json.loads((fixture.root / f"{name}.json").read_text())
            for name in ["realise", "instantiate", "timeout"]
        }

    @unittest.skipUnless(
        test_run_checks.MODULE_RUNNER_SUPPORTED, "module workers need Bash 5.1"
    )
    def test_isolated_module_uses_all_runner_cores(self):
        observed = self.run_native_fixture("ci/test", "modules", "k9s")
        realise = observed["realise"]
        self.assertEqual(realise[realise.index("--max-jobs") + 1], "1")
        self.assertEqual(realise[realise.index("--cores") + 1], "4")
        instantiate = observed["instantiate"]
        self.assertEqual(instantiate[instantiate.index("runtimeProfile") + 1], "all")
        self.assertEqual(instantiate[instantiate.index("runtimeVersions") + 1], "[]")
        self.assertEqual(observed["timeout"][:2], ["--kill-after=15s", "1800"])

    def test_common_keeps_two_bounded_build_jobs(self):
        observed = self.run_native_fixture("ci/common", "common", "pr")
        realise = observed["realise"]
        self.assertEqual(realise[realise.index("--max-jobs") + 1], "2")
        self.assertEqual(realise[realise.index("--cores") + 1], "2")
        self.assertEqual(observed["timeout"][:2], ["--kill-after=15s", "1800"])

    def test_task_selection_does_not_change_other_suites(self):
        self.assertEqual(check_jobs("ci/test"), 1)
        self.assertEqual(check_jobs("ci/common"), 2)

    def test_native_hang_guards_allow_suite_and_wrapper_cleanup(self):
        limits = [
            int(value)
            for value in re.findall(
                r"timeout-minutes:\s*([0-9]+)", WORKFLOW.read_text()
            )
        ]
        self.assertEqual(limits, [45, 40])
        self.assertGreater(limits[1] * 60, 1800 + 15)
        self.assertGreater(limits[0], limits[1])
        self.assertIn("NIX_CHECK_TARGET_SECONDS=600", WORKFLOW.read_text())

    def test_changed_pins_restore_own_module_before_newer_unrelated_cache(self):
        primary, prefixes = cache_configuration("modules-terraform", "new-pins")
        own_old = "nix-v3-Linux-ARM64-modules-terraform--old-pins-" + "a" * 40 + "-1"
        newer_other = "nix-v3-Linux-ARM64-modules-helm--new-pins-" + "b" * 40 + "-1"
        self.assertEqual(
            restored_cache(primary, prefixes, [newer_other, own_old]), own_old
        )
        self.assertIsNone(restored_cache(primary, prefixes, [newer_other]))

    def test_cache_scope_rejects_other_architecture_and_module_name_prefix(self):
        primary, prefixes = cache_configuration("modules-go", "new-pins")
        foreign = [
            "nix-v3-Linux-X64-modules-go--new-pins-" + "a" * 40 + "-1",
            "nix-v3-Linux-ARM64-modules-go-plus--new-pins-" + "b" * 40 + "-1",
            "nix-v2-Linux-ARM64-new-pins-modules-go-plus-" + "d" * 40 + "-1",
        ]
        self.assertIsNone(restored_cache(primary, prefixes, foreign))

    def test_matching_pins_precede_old_own_cache_and_save_uses_v3_primary(self):
        primary, prefixes = cache_configuration("modules-terraform", "new-pins")
        old = "nix-v3-Linux-ARM64-modules-terraform--old-pins-" + "a" * 40 + "-1"
        matching = "nix-v3-Linux-ARM64-modules-terraform--new-pins-" + "b" * 40 + "-1"
        self.assertEqual(restored_cache(primary, prefixes, [old, matching]), matching)
        source = WORKFLOW.read_text()
        self.assertIn("key: ${{ steps.nix-cache.outputs.cache-primary-key }}", source)
        self.assertTrue(primary.startswith("nix-v3-"))
        self.assertIn("always() && !cancelled()", source)

    def test_ambiguous_legacy_keys_are_not_migrated(self):
        primary, prefixes = cache_configuration("modules-go", "new-pins")
        own = "nix-v2-Linux-ARM64-new-pins-modules-go-" + "a" * 40 + "-1"
        child = "nix-v2-Linux-ARM64-new-pins-modules-go-plus-" + "b" * 40 + "-1"
        self.assertIsNone(restored_cache(primary, prefixes, [child, own]))
        self.assertEqual(len(prefixes), 2)
        self.assertTrue(all(prefix.startswith("nix-v3-") for prefix in prefixes))

    def test_both_native_architectures_follow_each_scheduled_module(self):
        fixture = test_plan_checks.PlanChecksTests(methodName="runTest")
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        for name, versions in [
            ("git", []),
            ("go", ["1.26", "1.27"]),
            ("rust", ["1.95"]),
        ]:
            fixture.module(name)
            fixture.write(
                f"catalog/{name}/module.toml", f"versions = {json.dumps(versions)}\n"
            )
        fixture.commit()
        result = fixture.invoke("--all")
        self.assertEqual(result.returncode, 0, result.stderr)
        chunks = json.loads(result.stdout)["chunks"]
        for filename in ["pr.yml", "release.yml"]:
            with self.subTest(filename=filename):
                source = (WORKFLOWS / filename).read_text()
                job = source.split("\n  test:\n", 1)[1].split("\n  common:\n", 1)[0]
                block = re.search(
                    r"(?m)^      matrix:\n((?:        .+\n)+)", job
                ).group(1)
                axes = [line.strip().split(":", 1) for line in block.splitlines()]
                self.assertEqual([axis[0] for axis in axes], ["chunk", "runner"])
                self.assertIn("fromJSON(needs.", axes[0][1])
                runners = [
                    value.strip() for value in axes[1][1].strip().strip("[]").split(",")
                ]
                self.assertEqual(runners, ["ubuntu-24.04", "ubuntu-24.04-arm"])
                jobs = [
                    (chunk["modules"], runner) for chunk in chunks for runner in runners
                ]
                self.assertEqual(
                    jobs[:2], [("go", "ubuntu-24.04"), ("go", "ubuntu-24.04-arm")]
                )
                self.assertEqual(len(jobs), 2 * len(chunks))
                self.assertEqual(len(set(jobs)), len(jobs))
                self.assertCountEqual(
                    jobs,
                    [
                        (name, runner)
                        for name in ["git", "go", "rust"]
                        for runner in runners
                    ],
                )


if __name__ == "__main__":
    unittest.main()
