import argparse
import os
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from harness import REPOSITORY, cache, checks, drift, graph, plan, previews, release, update


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(prog="harness", description="The catalog's orchestration.")
    commands = root.add_subparsers(dest="command", required=True)

    check = commands.add_parser("check", help="Run the checks of a suite in a phase")
    check.add_argument("suite", choices=checks.SUITES)
    check.add_argument("phase", choices=checks.PHASES)
    check.add_argument("modules", nargs="*")

    planner = commands.add_parser(
        "plan", help="Select CI checks from changed paths and dependencies"
    )
    planner.add_argument("--base", default="HEAD^1")
    planner.add_argument("--all", action="store_true", dest="all_targets")

    cache_commands = commands.add_parser("cache", help="The CI binary cache").add_subparsers(
        dest="action", required=True
    )
    cache_commands.add_parser(
        "hook", help="Copy built outputs into the cache (Nix post-build hook)"
    )
    prune = cache_commands.add_parser("prune", help="Drop cache entries that no check uses")
    prune.add_argument("directory")

    updates = commands.add_parser("update", help="Move a pinned input and print GitHub outputs")
    updates.add_argument("input", choices=("nixpkgs", "unstable", "nixos"))

    releases = commands.add_parser("release", help="Release helpers").add_subparsers(
        dest="action", required=True
    )
    tag = releases.add_parser("tag", help="Print the next tag when pinned inputs change")
    tag.add_argument("--base", default="HEAD^1", help="Git revision before the input change")
    manifest = releases.add_parser("manifest", help="Write dist/image.json for a release")
    manifest.add_argument("tag")
    build = releases.add_parser("build", help="Build the base disk into dist/")
    build.add_argument("arch", choices=release.ARCHITECTURES)

    reports = commands.add_parser("drift", help="Keep the catalog drift issue current")
    reports.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY", ""))

    commands.add_parser("graph", help="Write catalog/graph.json from the graph.toml files")
    commands.add_parser("previews", help="Write previews/, the theme previews of the site")
    return root


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parser().parse_args(argv)
    try:
        return run(arguments)
    except subprocess.CalledProcessError as error:
        if error.stderr:
            print(error.stderr, end="", file=sys.stderr)
        print(f"harness: command failed (exit {error.returncode}): {error.cmd}", file=sys.stderr)
        return 1
    except (OSError, ValueError) as error:
        print(f"harness: {error}", file=sys.stderr)
        return 1


def run(arguments: argparse.Namespace) -> int:
    os.chdir(REPOSITORY)
    if os.geteuid() == 0:
        subprocess.run(
            ["git", "config", "--global", "--add", "safe.directory", str(REPOSITORY)], check=True
        )
    dist = REPOSITORY / "dist"
    match arguments.command:
        case "plan":
            plan.outputs(plan.plan(arguments.base, arguments.all_targets))
        case "check":
            return checks.check([arguments.suite, arguments.phase, *arguments.modules])
        case "cache" if arguments.action == "hook":
            return cache.hook()
        case "cache":
            cache.prune(Path(arguments.directory))
        case "update":
            getattr(update, arguments.input)()
        case "release" if arguments.action == "tag":
            release.tag(arguments.base)
        case "release" if arguments.action == "manifest":
            release.manifest(arguments.tag, dist)
        case "release":
            release.build(arguments.arch, dist)
        case "drift":
            if not arguments.repository:
                print("drift needs --repository or GITHUB_REPOSITORY", file=sys.stderr)
                return 2
            drift.report(arguments.repository)
        case "graph":
            graph.write()
        case "previews":
            previews.write()
    return 0


if __name__ == "__main__":
    sys.exit(main())
