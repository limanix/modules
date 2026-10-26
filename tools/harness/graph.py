"""Build the catalog graph shown on the site.

The graph command reads graph.toml files from modules and catalog/_shared.
It collects node names, descriptions, links, kinds, and modules into
catalog/graph.json. Nodes from catalog/_shared have no kind or module.
The output uses a stable order and layout to make changes easy to review.

Module kinds come from checks/catalog-kinds.nix.
The CI planner also uses this file's helpers to find module directories.
"""

import json
import re
import tomllib
from pathlib import Path
from typing import Any

from harness import REPOSITORY

CATALOG = REPOSITORY / "catalog"
KINDS_FILE = REPOSITORY / "checks" / "catalog-kinds.nix"
SHARED = "_shared"
SHARED_PRIMARY = "theme"
INLINE_WIDTH = 100
QUOTED = re.compile(r'"([^"]+)"')


def kinds(source: str) -> list[str]:
    return QUOTED.findall(source)


def nodes_of(
    primary: str,
    tables: dict[str, dict[str, Any]],
    kind: str | None = None,
    module: str | None = None,
) -> list[dict[str, Any]]:
    ordered = [primary] if primary in tables else []
    ordered += sorted(name for name in tables if name != primary)
    return [{"id": name, **tables[name], "kind": kind, "module": module} for name in ordered]


def read_tables(directory: Path) -> dict[str, dict[str, Any]]:
    file = directory / "graph.toml"
    if not file.is_file():
        return {}
    return tomllib.loads(file.read_text())


def module_directories(catalog: Path, kind_names: list[str]) -> list[Path]:
    directories = []
    for kind in kind_names:
        kind_directory = catalog / kind
        if kind_directory.is_dir():
            directories += sorted(path for path in kind_directory.iterdir() if path.is_dir())
    return directories


def collect(catalog: Path = CATALOG, kind_names: list[str] | None = None) -> list[dict[str, Any]]:
    names = kind_names if kind_names is not None else kinds(KINDS_FILE.read_text())
    nodes = nodes_of(SHARED_PRIMARY, read_tables(catalog / SHARED))
    for directory in module_directories(catalog, names):
        nodes += nodes_of(
            directory.name, read_tables(directory), directory.parent.name, directory.name
        )
    return nodes


def quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def render_links(links: list[str]) -> str:
    inline = f'      "with": [{", ".join(quote(link) for link in links)}]'
    if len(inline) <= INLINE_WIDTH:
        return inline
    items = ",\n".join(f"        {quote(link)}" for link in links)
    return f'      "with": [\n{items}\n      ]'


def render_node(node: dict[str, Any]) -> str:
    fields = [
        f'      "id": {quote(node["id"])}',
        f'      "name": {quote(node["name"])}',
        f'      "text": {quote(node["text"])}',
        f'      "kind": {quote(node["kind"])}',
        f'      "module": {quote(node["module"])}',
        render_links(node.get("with", [])),
    ]
    return "    {\n" + ",\n".join(fields) + "\n    }"


def render(nodes: list[dict[str, Any]]) -> str:
    return '{\n  "modules": [\n' + ",\n".join(render_node(node) for node in nodes) + "\n  ]\n}\n"


def write(catalog: Path = CATALOG) -> Path:
    target = catalog / "graph.json"
    target.write_text(render(collect(catalog)))
    return target
