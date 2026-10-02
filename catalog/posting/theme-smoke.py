import asyncio
from pathlib import Path

from posting.__main__ import make_posting
from posting.locations import config_file


async def check_theme(expected):
    app = make_posting(collection=Path("collection"))
    async with app.run_test() as pilot:
        await pilot.pause()
        assert app.theme == expected, (app.theme, expected)


async def main():
    await check_theme("catppuccin-mocha")
    config_file().write_text("theme: galaxy\n")
    await check_theme("galaxy")


asyncio.run(main())
