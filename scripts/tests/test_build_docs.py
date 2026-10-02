"""Check subordinate module guides and release-aware links in prepared docs."""

import importlib.util
import tempfile
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "module_docs", Path(__file__).parents[1] / "build_docs.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class BuildDocsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "guides").mkdir()
        (self.root / "guides/index.md").write_text("# Modules\n")
        (self.root / "guides/catalog.md").write_text(
            "[Cozy](../catalog/cozy/README.md)\n[Check](../checks/common.nix)\n[Tasks](../Taskfile.yml)\n"
        )
        self.cozy = self.root / "catalog/cozy"
        self.cozy.mkdir(parents=True)
        (self.cozy / "README.md").write_text(
            "# Cozy\n[Guide](../../guides/catalog.md)\n[Playground](playground/README.md)\n"
        )

    def test_nested_guides_are_copied_and_connected(self):
        playground = self.cozy / "playground"
        playground.mkdir()
        (playground / "README.md").write_text(
            "# Playground\n[Guide](../../../guides/catalog.md)\n"
        )
        (playground / "app.py").write_text("raise RuntimeError('not documentation')\n")
        output = MODULE.prepare(self.root, "v8")
        self.assertEqual(
            (output / "modules/cozy/playground/README.md").read_text(),
            "# Playground\n[Guide](../../../catalog.md)\n",
        )
        main = (output / "modules/cozy/README.md").read_text()
        self.assertIn("[Guide](../../catalog.md)", main)
        self.assertIn("```{toctree}\n:hidden:\n\nplayground/README", main)
        self.assertFalse((output / "modules/cozy/playground/app.py").exists())
        catalog = (output / "catalog.md").read_text()
        self.assertIn("[Cozy](modules/cozy/README.md)", catalog)
        self.assertIn(
            "https://github.com/limanix/modules/blob/v8/checks/common.nix", catalog
        )
        self.assertIn(
            "https://github.com/limanix/modules/blob/v8/Taskfile.yml", catalog
        )

    def test_nested_symlink_fails_before_previous_output_is_removed(self):
        output = self.root / "build/docs"
        output.mkdir(parents=True)
        sentinel = output / "existing.md"
        sentinel.write_text("previous successful build")
        (self.cozy / "linked.md").symlink_to(self.cozy / "README.md")
        with self.assertRaisesRegex(ValueError, "must not be a symlink"):
            MODULE.prepare(self.root, "v8")
        self.assertEqual(sentinel.read_text(), "previous successful build")

    def test_ref_validation_precedes_output_changes(self):
        with self.assertRaisesRegex(ValueError, "MODULES_REF"):
            MODULE.prepare(self.root, "main")
        self.assertFalse((self.root / "build").exists())

    def test_shared_contract_is_not_a_module(self):
        shared = self.root / "catalog/_shared"
        shared.mkdir()
        (shared / "README.md").write_text("# Shared declarations\n")
        output = MODULE.prepare(self.root, "a" * 40)
        self.assertFalse((output / "modules/_shared").exists())


if __name__ == "__main__":
    unittest.main()
