"""Check runner validation and expected-error handling without a Nix store."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "run_checks.sh"
BASH_VERSION = subprocess.run(
    ["bash", "-c", "printf '%s.%s' ${BASH_VERSINFO[0]} ${BASH_VERSINFO[1]}"],
    text=True,
    capture_output=True,
    check=True,
).stdout
MODULE_RUNNER_SUPPORTED = tuple(map(int, BASH_VERSION.split("."))) >= (5, 1)


class RunChecksTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.environment = dict(os.environ, PATH=f"{self.root}:{os.environ['PATH']}")
        self.environment.pop("_LIMANIX_CHECK_BOUNDED", None)
        self.environment.pop("NIX_RUNTIME_PROFILE", None)
        self.environment.pop("NIX_RUNTIME_VERSIONS", None)
        self.stub("nproc", "print(4)")
        self.stub("nix-instantiate", "print('/nix/store/shared-fixture.drv')")
        self.stub(
            "nix-store",
            "import sys\nassert 'build-users-group' not in sys.argv\nprint('Built shared fixture')",
        )
        self.stub(
            "nix",
            """
import os
import sys
import time
arguments = sys.argv[1:]
time.sleep(float(os.environ.get('NIX_STUB_DELAY', '0')))
if 'builtins.currentSystem' in arguments:
    print(os.environ.get('NIX_STUB_SYSTEM', 'aarch64-linux'))
elif 'diagnostics' in arguments:
    print('expected-error\\towned option')
elif 'names' in arguments:
    print('go')
elif any('diagnostics.' in value and '.actual' in value for value in arguments):
    print(os.environ.get('NIX_STUB_DIAGNOSTIC', 'owned option'), file=sys.stderr)
    sys.exit(int(os.environ.get('NIX_STUB_DIAGNOSTIC_STATUS', '1')))
elif any(value == 'evaluation' or value.startswith('evaluationGroups.') and not value.endswith('.actual') for value in arguments) and '--raw' in arguments:
    print('composition')
else:
    print('{}')
""",
        )
        if shutil.which("timeout") is None:
            self.stub(
                "timeout",
                """
import os
import sys
arguments = sys.argv[1:]
assert arguments.pop(0) == '--kill-after=15s'
assert int(arguments.pop(0)) > 0
os.execvp(arguments[0], arguments)
""",
            )

    def stub(self, name, body):
        target = self.root / name
        target.write_text(f"#!{sys.executable}\n{body}\n")
        target.chmod(0o755)

    def invoke(self, *arguments, **environment):
        return subprocess.run(
            ["bash", str(SCRIPT), *arguments],
            cwd=self.root,
            env=dict(self.environment, **environment),
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )

    def test_common_requires_the_expected_diagnostic(self):
        result = self.invoke("common", "pr")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Passed common pr", result.stdout)
        self.assertIn("Built shared fixture", result.stdout)

    def test_unrelated_evaluation_failure_is_not_accepted(self):
        result = self.invoke("common", "pr", NIX_STUB_DIAGNOSTIC="network unavailable")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Missing expected diagnostic: owned option", result.stderr)

    def test_unexpected_success_is_not_accepted(self):
        result = self.invoke("common", "pr", NIX_STUB_DIAGNOSTIC_STATUS="0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("but it succeeded", result.stderr)

    def test_release_evaluation_runs_integration_diagnostics(self):
        result = self.invoke("common", "release-eval")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout.count("Checking expected diagnostic: expected-error"), 2
        )

    def test_base_group_owns_common_smoke_and_integration_diagnostics(self):
        result = self.invoke("common", "release-eval", NIX_INTEGRATION_GROUP="base")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Built shared fixture", result.stdout)
        self.assertEqual(
            result.stdout.count("Checking expected diagnostic: expected-error"), 2
        )
        self.assertIn("Checking catalog integration: composition", result.stdout)

    def test_heavy_groups_run_cases_without_duplicate_common_fixtures(self):
        for group in ["compositions", "versions"]:
            with self.subTest(group=group):
                result = self.invoke(
                    "common", "release-eval", NIX_INTEGRATION_GROUP=group
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(
                    "Checking catalog integration: composition", result.stdout
                )
                self.assertNotIn("Checking expected diagnostic:", result.stdout)
                self.assertNotIn("Built shared fixture", result.stdout)

    def test_integration_groups_reject_unknown_names_and_wrong_profiles(self):
        for profile, group in [
            ("release-eval", "bad;touch marker"),
            ("pr", "base"),
            ("release-smoke", "versions"),
        ]:
            with self.subTest(profile=profile, group=group):
                result = self.invoke("common", profile, NIX_INTEGRATION_GROUP=group)
                self.assertEqual(result.returncode, 2)
        self.assertFalse((self.root / "marker").exists())

    def test_invalid_limits_fail_before_nix(self):
        for name in [
            "NIX_CHECK_JOBS",
            "NIX_CHECK_BATCH_SIZE",
            "NIX_BUILD_CORES",
            "NIX_CHECK_TIMEOUT",
        ]:
            for value in ["0", "-1", "x", "1;touch marker"]:
                with self.subTest(name=name, value=value):
                    result = self.invoke("common", "pr", **{name: value})
                    self.assertEqual(result.returncode, 2)
                    self.assertIn("positive integers", result.stderr)
        self.assertFalse((self.root / "marker").exists())

    def test_native_linux_is_required(self):
        result = self.invoke("common", "pr", NIX_STUB_SYSTEM="aarch64-darwin")
        self.assertEqual(result.returncode, 2)
        self.assertIn("native Linux runner", result.stderr)

    def test_profiles_and_module_names_are_restricted(self):
        for arguments in [
            ("invalid",),
            ("common", "invalid"),
            ("common", "pr", "extra"),
            ("modules", "go;touch marker"),
            ("modules", "../go"),
        ]:
            with self.subTest(arguments=arguments):
                self.assertEqual(self.invoke(*arguments).returncode, 2)
        self.assertFalse((self.root / "marker").exists())

    def test_runtime_profiles_versions_and_scope_fail_before_nix(self):
        selections = [
            (("modules", "go"), {"NIX_RUNTIME_PROFILE": "bad;touch marker"}),
            (
                ("modules", "go"),
                {"NIX_RUNTIME_PROFILE": "pr", "NIX_RUNTIME_VERSIONS": "1;touch-marker"},
            ),
            (("modules", "go"), {"NIX_RUNTIME_VERSIONS": "1.26"}),
            (
                ("modules",),
                {"NIX_RUNTIME_PROFILE": "pr", "NIX_RUNTIME_VERSIONS": "1.26"},
            ),
            (
                ("modules", "go", "rust"),
                {"NIX_RUNTIME_PROFILE": "pr", "NIX_RUNTIME_VERSIONS": "1.26"},
            ),
            (("common", "pr"), {"NIX_RUNTIME_PROFILE": "pr"}),
        ]
        for arguments, environment in selections:
            with self.subTest(arguments=arguments, environment=environment):
                result = self.invoke(*arguments, **environment)
                self.assertEqual(result.returncode, 2, result.stderr)
        self.assertFalse((self.root / "marker").exists())

    @unittest.skipUnless(
        MODULE_RUNNER_SUPPORTED, "Module scheduler requires Bash 5.1 or later"
    )
    def test_module_runtime_selection_reaches_native_check_arguments(self):
        record = self.root / "instantiate.json"
        self.stub(
            "nix-instantiate",
            "import json\nimport os\nimport sys\nfrom pathlib import Path\nPath(os.environ['NIX_STUB_RECORD']).write_text(json.dumps(sys.argv))\nprint('/nix/store/shared-fixture.drv')",
        )
        for profile, versions in [("all", ""), ("pr", "1.26 1.27")]:
            with self.subTest(profile=profile):
                result = self.invoke(
                    "modules",
                    "go",
                    NIX_RUNTIME_PROFILE=profile,
                    NIX_RUNTIME_VERSIONS=versions,
                    NIX_STUB_RECORD=str(record),
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                arguments = json.loads(record.read_text())
                self.assertEqual(
                    arguments[arguments.index("runtimeProfile") + 1], profile
                )
                self.assertEqual(
                    json.loads(arguments[arguments.index("runtimeVersions") + 1]),
                    versions.split(),
                )
                self.assertIn(f"runtime {profile}", result.stdout)
                self.assertIn("Passed 1 module suites", result.stdout)

    @unittest.skipUnless(
        shutil.which("timeout"), "GNU timeout is required for process-group test"
    )
    def test_timeout_terminates_a_blocked_nix_process(self):
        started = time.monotonic()
        result = self.invoke("common", "pr", NIX_CHECK_TIMEOUT="1", NIX_STUB_DELAY="20")
        self.assertEqual(result.returncode, 124, result.stderr)
        self.assertLess(time.monotonic() - started, 5)


if __name__ == "__main__":
    unittest.main()
