# Posting

Installs Posting, a terminal client for HTTP APIs, and sets `POSTING_THEME` to
the guest's theme by default: `ansi-dark`, Textual's theme in the terminal's own
colors and background, with the default `system` flavor, or the Catppuccin theme
of a flavor that `[theme]` in `limanix.toml` selects, such as
`catppuccin-latte`. On a light terminal, set `POSTING_THEME=ansi-light` in
`[env]`.

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
requests in a collection to reuse them. Open a project collection with:

```console
posting --collection ./requests
```

The collection directory must already exist. Use `posting locate collection` to
find the default collection directory and `posting locate config` to find your
configuration file. Posting stores personal settings in
`~/.config/posting/config.yaml`, respecting `XDG_CONFIG_HOME`. Set `theme` in
that file to override the module's `POSTING_THEME` default. See the
[Posting guide](https://posting.sh/guide/) for collections and request
configuration.

## Configuration and integration

| Boundary | Contract |
| -- | -- |
| Settings | `environment.variables.POSTING_THEME` defaults to `ansi-dark` with the system flavor and to `catppuccin-<flavor>` with a Catppuccin flavor; `[env]` and personal YAML may override it |
| Personal state | `~/.config/posting/config.yaml` and request collections, respecting XDG configuration |
| Integration | Needs no other module; collections live with your projects |
| Services and capabilities | No API server or language-support declarations |

## Corner cases

| Case | Behavior or next step |
| -- | -- |
| Collection is missing | Create or select an existing directory before using `--collection` |
| API is unreachable | Check the URL from inside the guest; guest localhost is separate from Mac localhost |
| Personal theme wins | The YAML setting overrides the managed environment default |

## Guarantees

| Guarantee | Checked by |
| -- | -- |
| The module installs the base Posting package and its config-location command runs | `eval.defaults`, `run.commands` |
| POSTING_THEME defaults to ansi-dark, a theme that Posting offers | `eval.defaults`, `run.commands` |
| POSTING_THEME follows the guest's flavor | `eval.latte` |
| An ordinary assignment can replace POSTING_THEME | `eval.themeOverride` |
