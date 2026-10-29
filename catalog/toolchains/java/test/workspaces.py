import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


WRAPPER = Path(sys.argv.pop(1)).resolve()


class Workspaces(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        self.cache = self.base / "cache"
        self.env = {key: value for key, value in os.environ.items() if key != "LMX_JDTLS_ROOT"}
        self.env.update(HOME=str(self.base / "home"), XDG_CACHE_HOME=str(self.cache))
        self.launcher = self.base / "launcher"
        self.launcher.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "print(json.dumps({'pid': os.getpid(), 'argv': sys.argv[1:],"
            " 'root': os.environ.get('LMX_JDTLS_ROOT')}))\n"
        )
        self.launcher.chmod(0o700)
        self.first = self.project("one/service")
        self.second = self.project("two/service")

    def project(self, name):
        path = self.base / "projects" / name
        path.mkdir(parents=True)
        return path

    def run_wrapper(self, cwd, *arguments, root=None, env=None):
        environment = dict(env or self.env)
        if root is not None:
            environment["LMX_JDTLS_ROOT"] = str(root)
        child = subprocess.Popen(
            [sys.executable, str(WRAPPER), str(self.launcher), *arguments],
            cwd=cwd,
            env=environment,
            stdout=subprocess.PIPE,
            text=True,
        )
        output, _ = child.communicate(timeout=10)
        self.assertEqual(child.returncode, 0)
        result = json.loads(output)
        self.assertEqual(result["pid"], child.pid, "the wrapper must exec the launcher")
        self.assertIsNone(result["root"], "the launcher must not see LMX_JDTLS_ROOT")
        return result["argv"]

    def data(self, cwd, root=None):
        arguments = self.run_wrapper(cwd, root=root)
        self.assertEqual(arguments[-2], "-data")
        workspace = Path(arguments[-1])
        self.assertTrue(workspace.is_dir())
        self.assertEqual(workspace.parent, self.cache / "limanix" / "jdtls")
        return workspace

    def test_workspace_follows_the_full_project_path(self):
        first = self.data(self.first)
        self.assertNotEqual(self.data(self.second), first)
        self.assertEqual(self.data(self.first), first)
        self.assertEqual(self.data(self.base, root=self.first), first)
        self.assertEqual(self.data(self.base, root=self.first / ".." / "service" / "."), first)
        alias = self.base / "alias"
        alias.symlink_to(self.first, target_is_directory=True)
        self.assertEqual(self.data(self.base, root=alias), first)

    def test_arguments_are_kept(self):
        arguments = ["--jvm-arg=-javaagent:/test/lombok.jar", "--extra"]
        self.assertEqual(self.run_wrapper(self.first, *arguments)[:-2], arguments)

    def test_explicit_data_is_kept(self):
        custom = str(self.base / "custom")
        for arguments in (["-data", custom], [f"-data={custom}"]):
            self.assertEqual(self.run_wrapper(self.first, *arguments, root=self.second), arguments)
        self.assertFalse(self.cache.exists())

    def test_relative_cache_home_falls_back_to_home(self):
        env = dict(self.env, XDG_CACHE_HOME="relative")
        arguments = self.run_wrapper(self.first, env=env)
        self.assertEqual(
            Path(arguments[-1]).parent, self.base / "home" / ".cache" / "limanix" / "jdtls"
        )


if __name__ == "__main__":
    unittest.main()
