#!/usr/bin/env python3
"""Prepare module Markdown for the LimaNix documentation site.

Validate source documents before replacing build/docs, rewrite site-relative
links, and connect module guides through Sphinx toctrees. This tool does not
render the site or evaluate Nix modules.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_LINK = re.compile(
    r"\]\(\.\./((?:checks|catalog|scripts)/[^)]*?\.(?:nix|py|sh)"
    r"|Taskfile\.yml)(#[^)]*)?\)"
)
NESTED_GUIDE_LINK = re.compile(r"\]\(((?:\.\./)+)guides/")
MODULE_SOURCE_LINK = re.compile(
    r"\]\((?!https?:|#|\.\./)([^)#]+?\.(?:nix|py|sh|toml))(#[^)]*)?\)"
)


def read_guides(root: Path) -> dict[Path, str]:
    """Read guide Markdown and reject links that copytree would follow."""
    guides = root / "guides"
    if guides.is_symlink():
        raise ValueError("guides/ must not be a symlink")
    for name in ("index.md", "catalog.md", "writing-modules.md"):
        if not (guides / name).is_file():
            raise ValueError(f"Missing guide: guides/{name}")
    documents = {}
    for source in sorted(guides.rglob("*")):
        if source.is_symlink():
            raise ValueError(f"guide source must not be a symlink: {source}")
        if source.is_file() and source.suffix == ".md":
            documents[source.relative_to(guides)] = source.read_text(encoding="utf-8")
    return documents


def read_module_documents(root: Path) -> dict[Path, dict[Path, str]]:
    """Collect module README files and subordinate Markdown before writing."""
    catalog = root / "catalog"
    if not catalog.is_dir():
        raise ValueError("Missing module directory: catalog/")
    modules = sorted(path for path in catalog.iterdir() if path.is_dir())
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
        sources = {}
        for document in sorted(module.rglob("*.md")):
            if document.is_symlink():
                raise ValueError(
                    f"module documentation must not be a symlink: {document}"
                )
            sources[document.relative_to(module)] = document.read_text(encoding="utf-8")
        documents[module] = sources
    return documents


def prepare(root: Path, ref: str) -> Path:
    if not re.fullmatch(r"v[1-9][0-9]*|[0-9a-f]{40}", ref):
        raise ValueError(
            "MODULES_REF must be a release tag such as v4 or a full commit SHA"
        )

    guides = read_guides(root)
    modules = read_module_documents(root)
    output = root / "build" / "docs"
    if output.parent.is_symlink() or output.is_symlink():
        raise ValueError("build/ and build/docs/ must not be symlinks")
    if output.exists():
        shutil.rmtree(output)
    shutil.copytree(root / "guides", output)

    source_url = f"https://github.com/limanix/modules/blob/{ref}/"
    for relative, text in guides.items():
        text = SOURCE_LINK.sub(
            lambda match: f"]({source_url}{match[1]}{match[2] or ''})", text
        )
        text = text.replace("](../catalog/", "](modules/")
        (output / relative).write_text(text, encoding="utf-8")

    for module, documents in modules.items():
        target = output / "modules" / module.name / "README.md"
        target.parent.mkdir(parents=True)
        text = MODULE_SOURCE_LINK.sub(
            rf"]({source_url}catalog/{module.name}/\1\2)", documents[Path("README.md")]
        )
        entries = []
        for relative, nested_text in documents.items():
            if relative == Path("README.md"):
                continue
            nested_target = target.parent / relative
            nested_target.parent.mkdir(parents=True, exist_ok=True)
            nested_text = NESTED_GUIDE_LINK.sub(r"](\1", nested_text)
            nested_target.write_text(nested_text, encoding="utf-8")
            entries.append(relative.with_suffix("").as_posix())
        if entries:
            text += "\n```{toctree}\n:hidden:\n\n" + "\n".join(entries) + "\n```\n"
        target.write_text(text.replace("](../../guides/", "](../../"), encoding="utf-8")

    # _shared is a page for module authors, not a catalog entry.
    with (output / "catalog.md").open("a", encoding="utf-8") as catalog:
        catalog.write(
            "\n```{toctree}\n:hidden:\n:glob:\n\nmodules/[!_]*/README\n```\n"
        )
    with (output / "writing-modules.md").open("a", encoding="utf-8") as guide:
        guide.write("\n```{toctree}\n:hidden:\n\nmodules/_shared/README\n```\n")
    return output


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root", type=Path, default=ROOT, help="Modules repository directory"
    )
    parser.add_argument(
        "--ref", required=True, help="Release tag or commit SHA for source links"
    )
    args = parser.parse_args(argv)
    try:
        output = prepare(args.root, args.ref)
    except ValueError as error:
        print(f"docs/prepare: {error}", file=sys.stderr)
        return 2
    except OSError as error:
        print(f"docs/prepare: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("docs/prepare: interrupted", file=sys.stderr)
        return 130
    print(f"Prepared documentation in {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
