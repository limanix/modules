# Colors of the guest, chosen once in the declaration and read by modules and the platform.
#
# Identity: one theme per system. `flavor` names a Catppuccin flavor; `palette` is its table in
# palette.toml and is read-only.
# Merge: `flavor` holds one value. Equal definitions agree; different definitions at the same
# priority fail evaluation.
# Conflicts: modules read the theme and never set it. The user chooses the flavor.
{ config, lib, ... }:
let
  palettes = builtins.fromTOML (builtins.readFile ./palette.toml);
in
{
  options.lmx.capabilities.theme = {
    flavor = lib.mkOption {
      type = lib.types.enum (builtins.attrNames palettes);
      default = "mocha";
      description = "Catppuccin flavor of the guest: latte, frappe, macchiato or mocha.";
    };
    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      default = palettes.${config.lmx.capabilities.theme.flavor};
      defaultText = lib.literalMD "the table of `flavor` in `palette.toml`";
      description = "Colors of the flavor by name, such as `blue`, as `#rrggbb`.";
    };
  };
}
