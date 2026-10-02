"""Prepare this repository's Markdown section for the LimaNix documentation site."""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_LINK = re.compile(
    r"\]\(\.\./((?:checks|catalog|scripts)/[^)]*?\.(?:nix|py|sh)|Taskfile\.yml)(#[^)]*)?\)"
)


def prepare(root: Path, ref: str) -> Path:
    if not re.fullmatch(r"v[1-9][0-9]*|[0-9a-f]{40}", ref):
        raise ValueError(
            "MODULES_REF must be a release tag such as v4 or a full commit SHA"
        )

    guides = root / "guides"
    for name in ("index.md", "catalog.md"):
        if not (guides / name).is_file():
            raise ValueError(f"Missing guide: guides/{name}")

    modules = sorted(
        path
        for path in (root / "catalog").iterdir()
        if path.is_dir() and not (path.name == "_shared" and not path.is_symlink())
    )
    if not modules:
        raise ValueError("No modules found in catalog/")
    documents = {}
    for module in modules:
        readme = module / "README.md"
        if module.is_symlink() or readme.is_symlink():
            raise ValueError(f"module documentation must not be a symlink: {readme}")
        if not readme.is_file():
            raise ValueError(
                f"Missing module documentation: catalog/{module.name}/README.md"
            )
        documents[module] = sorted(
            path for path in module.rglob("*.md") if path != readme
        )
        for document in documents[module]:
            if document.is_symlink():
                raise ValueError(
                    f"module documentation must not be a symlink: {document}"
                )

    output = root / "build" / "docs"
    if output.parent.is_symlink() or output.is_symlink():
        raise ValueError("build/ and build/docs/ must not be symlinks")
    if output.exists():
        shutil.rmtree(output)
    shutil.copytree(guides, output)

    source_url = f"https://github.com/limanix/modules/blob/{ref}/"
    for guide in output.rglob("*.md"):
        text = guide.read_text(encoding="utf-8")
        text = SOURCE_LINK.sub(
            lambda match: f"]({source_url}{match[1]}{match[2] or ''})", text
        )
        text = text.replace("](../catalog/", "](modules/")
        guide.write_text(text, encoding="utf-8")

    for module in modules:
        target = output / "modules" / module.name / "README.md"
        target.parent.mkdir(parents=True)
        text = (module / "README.md").read_text(encoding="utf-8")
        nested = documents[module]
        entries = []
        for document in nested:
            relative = document.relative_to(module)
            nested_target = target.parent / relative
            nested_target.parent.mkdir(parents=True, exist_ok=True)
            nested_text = re.sub(
                r"\]\(((?:\.\./)+)guides/",
                r"](\1",
                document.read_text(encoding="utf-8"),
            )
            nested_target.write_text(nested_text, encoding="utf-8")
            entries.append(relative.with_suffix("").as_posix())
        if entries:
            text += "\n```{toctree}\n:hidden:\n\n" + "\n".join(entries) + "\n```\n"
        target.write_text(text.replace("](../../guides/", "](../../"), encoding="utf-8")

    with (output / "catalog.md").open("a", encoding="utf-8") as catalog:
        catalog.write("\n```{toctree}\n:hidden:\n:glob:\n\nmodules/*/README\n```\n")

    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--ref", required=True, help="Release tag or commit SHA for source links"
    )
    args = parser.parse_args()

    try:
        output = prepare(ROOT, args.ref)
    except (OSError, ValueError) as error:
        print(f"docs/prepare: {error}", file=sys.stderr)
        return 1
    print(f"Prepared documentation in {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
