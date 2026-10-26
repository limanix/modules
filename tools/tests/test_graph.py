import json
from pathlib import Path

from harness import REPOSITORY, graph


def write(directory: Path, text: str) -> None:
    directory.mkdir(parents=True)
    (directory / "graph.toml").write_text(text)


def test_collect_preserves_node_order_and_links(tmp_path: Path) -> None:
    write(tmp_path / "_shared", '[theme]\nname = "`[theme]`"\ntext = "One theme."\n')
    write(
        tmp_path / "shell" / "zsh",
        '[pure]\nname = "Pure"\ntext = "A prompt."\nwith = ["zsh"]\n\n'
        '[zsh]\nname = "Zsh"\ntext = "A shell."\n'
        'with = ["pure", "theme"]\n',
    )
    (tmp_path / "shell" / "notes.md").write_text("not a module\n")
    write(tmp_path / "modules" / "docker", '[docker]\nname = "Docker"\ntext = "Engine."\n')
    rendered = graph.render(graph.collect(tmp_path, ["shell", "toolchains", "modules"]))
    nodes = json.loads(rendered)["modules"]
    assert [node["id"] for node in nodes] == ["theme", "zsh", "pure", "docker"]
    assert nodes[0] == {
        "id": "theme",
        "name": "`[theme]`",
        "text": "One theme.",
        "kind": None,
        "module": None,
        "with": [],
    }
    assert nodes[1]["with"] == ["pure", "theme"]
    assert nodes[2]["with"] == ["zsh"]
    assert nodes[3]["with"] == []
    assert [(node["kind"], node["module"]) for node in nodes[1:]] == [
        ("shell", "zsh"),
        ("shell", "zsh"),
        ("modules", "docker"),
    ]


def test_catalog_graph_is_current() -> None:
    assert graph.render(graph.collect()) == (REPOSITORY / "catalog" / "graph.json").read_text()
