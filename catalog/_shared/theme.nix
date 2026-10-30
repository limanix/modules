# Colors of the guest, chosen once in the declaration and read by modules and the platform.
#
# Identity: one theme per system. `name` is `system`, the terminal's own colors and background,
# or a table of themes.toml. `palette` holds the theme's colors by role, `dark` tells whether they
# sit on a dark background, `ansi` holds the terminal colors in ansi.toml that stand for the same
# roles, and `colors` holds what a module draws with; all four are read-only.
# Merge: `name` holds one value. Equal definitions agree; different definitions at the same
# priority fail evaluation.
# Conflicts: modules read the theme and never set it. The user chooses the theme.
{ config, lib, ... }:
let
  themes = builtins.fromTOML (builtins.readFile ./themes.toml);
  terminal = lib.mapAttrs (_: color: if color == "default" then null else color) (
    builtins.fromTOML (builtins.readFile ./ansi.toml)
  );
  inherit (config.lmx.capabilities.theme) name;
  system = name == "system";
  chosen = themes.${if system then "catppuccin-mocha" else name};
  palette = removeAttrs chosen [
    "dark"
    "title"
    "homepage"
  ];
in
{
  options.lmx.capabilities.theme = {
    name = lib.mkOption {
      type = lib.types.enum ([ "system" ] ++ builtins.attrNames themes);
      default = "system";
      description = ''
        Colors of the guest: system, the terminal's own colors and background, or a theme of
        themes.toml, such as tokyo-night.
      '';
    };
    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      default = palette;
      defaultText = lib.literalMD "the colors of `name` in `themes.toml`, catppuccin-mocha's for `system`";
      description = ''
        Colors of the theme by role, such as `accent` or `red`, as `#rrggbb`. With system they are
        catppuccin-mocha's, for a tool that knows only explicit colors.
      '';
    };
    dark = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = chosen.dark;
      defaultText = lib.literalMD "`dark` of `name` in `themes.toml`, catppuccin-mocha's for `system`";
      description = "Whether the palette's colors sit on a dark background.";
    };
    ansi = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr (lib.types.ints.between 0 15));
      readOnly = true;
      default = terminal;
      defaultText = lib.literalMD "the table in `ansi.toml`";
      description = ''
        The terminal color that stands for each role of `palette` with system: one of the
        terminal's 16 colors, or null for its default foreground or background.
      '';
    };
    colors = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.nullOr (lib.types.either lib.types.str (lib.types.ints.between 0 15))
      );
      readOnly = true;
      default = if system then terminal else palette;
      defaultText = lib.literalMD "`ansi` for `system`, `palette` otherwise";
      description = ''
        The color a module draws each role with: the palette's `#rrggbb`, or with system the
        terminal color of `ansi`.
      '';
    };
  };
}
