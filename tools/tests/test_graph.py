from pathlib import Path

from harness import REPOSITORY, graph


def test_kinds_come_from_the_nix_list() -> None:
    assert graph.kinds('[\n  "shell"\n  "toolchains"\n  "modules"\n]\n') == [
        "shell",
        "toolchains",
        "modules",
    ]


def write(directory: Path, text: str) -> None:
    directory.mkdir(parents=True)
    (directory / "graph.toml").write_text(text)


def test_render_orders_nodes_and_wraps_long_links(tmp_path: Path) -> None:
    write(tmp_path / "_shared", '[theme]\nname = "`[theme]`"\ntext = "One theme."\n')
    write(
        tmp_path / "shell" / "zsh",
        '[pure]\nname = "Pure"\ntext = "A prompt."\nwith = ["zsh"]\n\n'
        '[zsh]\nname = "Zsh"\ntext = "A shell."\n'
        'with = ["pure", "a-very-long-node-name", "another-very-long-node-name", '
        '"yet-another-long-node-name"]\n',
    )
    (tmp_path / "shell" / "notes.md").write_text("not a module\n")
    write(tmp_path / "modules" / "docker", '[docker]\nname = "Docker"\ntext = "Engine."\n')
    rendered = graph.render(graph.collect(tmp_path, ["shell", "toolchains", "modules"]))
    assert rendered == (
        "{\n"
        '  "modules": [\n'
        "    {\n"
        '      "id": "theme",\n'
        '      "name": "`[theme]`",\n'
        '      "text": "One theme.",\n'
        '      "with": []\n'
        "    },\n"
        "    {\n"
        '      "id": "zsh",\n'
        '      "name": "Zsh",\n'
        '      "text": "A shell.",\n'
        '      "with": [\n'
        '        "pure",\n'
        '        "a-very-long-node-name",\n'
        '        "another-very-long-node-name",\n'
        '        "yet-another-long-node-name"\n'
        "      ]\n"
        "    },\n"
        "    {\n"
        '      "id": "pure",\n'
        '      "name": "Pure",\n'
        '      "text": "A prompt.",\n'
        '      "with": ["zsh"]\n'
        "    },\n"
        "    {\n"
        '      "id": "docker",\n'
        '      "name": "Docker",\n'
        '      "text": "Engine.",\n'
        '      "with": []\n'
        "    }\n"
        "  ]\n"
        "}\n"
    )


def test_catalog_graph_is_current() -> None:
    assert graph.render(graph.collect()) == (REPOSITORY / "catalog" / "graph.json").read_text()
