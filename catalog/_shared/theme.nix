# Colors of the guest, chosen once in the declaration and read by modules and the platform.
#
# Identity: one theme per system. `flavor` is `system`, the terminal's own colors and background,
# or a Catppuccin flavor. `palette` is the flavor's table in palette.toml, and `ansi` the terminal
# colors in ansi.toml that stand for the same names; both are read-only.
# Merge: `flavor` holds one value. Equal definitions agree; different definitions at the same
# priority fail evaluation.
# Conflicts: modules read the theme and never set it. The user chooses the flavor.
{ config, lib, ... }:
let
  palettes = builtins.fromTOML (builtins.readFile ./palette.toml);
  terminal = lib.mapAttrs (_: color: if color == "default" then null else color) (
    builtins.fromTOML (builtins.readFile ./ansi.toml)
  );
  inherit (config.lmx.capabilities.theme) flavor;
in
{
  options.lmx.capabilities.theme = {
    flavor = lib.mkOption {
      type = lib.types.enum ([ "system" ] ++ builtins.attrNames palettes);
      default = "system";
      description = ''
        Colors of the guest: system, the terminal's own colors and background, or a Catppuccin
        flavor: latte, frappe, macchiato or mocha.
      '';
    };
    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      default = palettes.${if flavor == "system" then "mocha" else flavor};
      defaultText = lib.literalMD "the table of `flavor` in `palette.toml`, Mocha's for `system`";
      description = ''
        Colors of the flavor by name, such as `blue`, as `#rrggbb`. With system they are Mocha's,
        for a tool that knows only explicit colors.
      '';
    };
    ansi = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr (lib.types.ints.between 0 15));
      readOnly = true;
      default = terminal;
      defaultText = lib.literalMD "the table in `ansi.toml`";
      description = ''
        The terminal color that stands for each name of `palette` with the system flavor: one of
        the terminal's 16 colors, or null for its default foreground or background.
      '';
    };
  };
}
