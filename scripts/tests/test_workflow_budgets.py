"""Keep native module jobs within their CPU and timeout budgets."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

import test_run_checks

WORKFLOW = (
    Path(__file__).resolve().parents[2] / ".github" / "workflows" / "nix-tests.yml"
)


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
        self.assertEqual(limits, ["300"])
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
        self.assertEqual(observed["timeout"][:2], ["--kill-after=15s", "300"])

    def test_common_keeps_two_bounded_build_jobs(self):
        observed = self.run_native_fixture("ci/common", "common", "pr")
        realise = observed["realise"]
        self.assertEqual(realise[realise.index("--max-jobs") + 1], "2")
        self.assertEqual(realise[realise.index("--cores") + 1], "2")
        self.assertEqual(observed["timeout"][:2], ["--kill-after=15s", "300"])

    def test_task_selection_does_not_change_other_suites(self):
        self.assertEqual(check_jobs("ci/test"), 1)
        self.assertEqual(check_jobs("ci/common"), 2)

    def test_native_workflow_preserves_outer_timeouts(self):
        limits = [
            int(value)
            for value in re.findall(
                r"timeout-minutes:\s*([0-9]+)", WORKFLOW.read_text()
            )
        ]
        self.assertEqual(limits, [7, 6])


if __name__ == "__main__":
    unittest.main()
