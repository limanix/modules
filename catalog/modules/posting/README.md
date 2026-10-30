# Posting

Installs Posting, a terminal client for HTTP APIs, and sets its default theme
from `[theme]` in `limanix.toml`.

## Select

```toml
[nixos]
modules = ["lmx:posting"]
```

Add the selector to your VM's `nixos.modules` list and
[apply the change](https://docs.limanix.dev/vms/update#apply-a-change).

## Versions

Posting comes from the catalog's
[base Nixpkgs revision](../../README.md#package-pins-and-unfree-permissions).
This module has no version lines.

## Use

Run Posting inside the VM:

```console
posting
```

The interface lets you compose HTTP requests and inspect their responses. Save
requests in a collection to reuse them.

| Key | Action |
| -- | -- |
| Ctrl-J | Send the request |
| Ctrl-S | Save the request to the collection |
| F1 | Show the key bindings of the focused widget |

To open a collection from your project, first create its directory, then run:

```console
posting --collection ./requests
```

`posting locate collection` shows the default collection directory. The
[Posting guide](https://posting.sh/guide/) covers collections and request
settings.

## Theme

The module adds a `limanix` theme to Posting, drawn from the palette of the
guest's theme in `[theme]` of `limanix.toml`, and sets `POSTING_THEME=limanix`.
Posting fails to start with Textual's terminal themes `ansi-dark` and
`ansi-light`, so with the default `system` theme it draws catppuccin-mocha's
colors, with their own background. For a light terminal, choose a light theme in
`[theme]`, or add one of Posting's own themes to your existing `[env]` table:

```toml
[env]
POSTING_THEME = "catppuccin-latte"
```

Personal settings are in `~/.config/posting/config.yaml`, following
`XDG_CONFIG_HOME`. A `theme` in that file overrides the environment value.
`posting locate config` shows the configuration file.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | `environment.variables.POSTING_THEME` defaults to `limanix`, drawn from the guest's palette; `[env]` and personal YAML may override it |
| Personal state | `~/.config/posting/config.yaml` and request collections, respecting XDG configuration |
| Integration | Needs no other module; collections live with your projects |
| Services and capabilities | No API server or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Collection is missing | Create or select an existing directory before using `--collection` |
| API is unreachable | Check the URL from inside the guest; guest localhost is separate from Mac localhost |
| Personal theme wins | The YAML setting overrides the managed environment default |
