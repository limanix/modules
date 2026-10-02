# Posting

Installs Posting, a terminal client for HTTP APIs, with Catppuccin Mocha as its default theme.

```toml
[nixos]
modules = ["lmx:posting"]
```

Add the selector to your VM's `nixos.modules` list and [apply the change](https://limanix.dev/categories/client/virtual-machines.html#apply-a-configuration-change).

## Versions

Posting comes from the catalog's [base Nixpkgs revision](../../guides/concepts.md#nixos-version-and-package-pins).
This module has no version lines.

## Use

Run Posting inside the VM:

```console
posting
```

The interface lets you compose HTTP requests and inspect their responses.
Save requests in a collection to reuse them.
Open a project collection with:

```console
posting --collection ./requests
```

The collection directory must already exist.
Use `posting locate collection` to find the default collection directory and `posting locate config` to find your configuration file.
Posting stores personal settings in `~/.config/posting/config.yaml`, respecting `XDG_CONFIG_HOME`.
Set `theme` in that file to override the module's `POSTING_THEME` default.
See the [Posting guide](https://posting.sh/guide/) for collections and request configuration.

## Configuration and integration

| Boundary | Contract |
|---|---|
| Settings | `environment.variables.POSTING_THEME` defaults to `catppuccin-mocha`; personal YAML may override it |
| Personal state | `~/.config/posting/config.yaml` and request collections, respecting XDG configuration |
| Integration | Cozy ships a project collection for its notes API |
| Services and capabilities | No API server or language-support declarations |

## Corner cases

| Case | Behavior or next step |
|---|---|
| Collection is missing | Create or select an existing directory before using `--collection` |
| API is unreachable | Check the URL from inside the guest; guest localhost is separate from Mac localhost |
| Personal theme wins | The YAML setting overrides the managed environment default |

## Guarantees

| Guarantee | Covered by |
|---|---|
| Installs the base Nixpkgs Posting package | `check.nix` |
| Uses Catppuccin Mocha by default and respects a personal YAML theme | `check.nix`, `smoke.nix`: theme |
