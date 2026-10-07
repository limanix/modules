{ evalSystem, pkgs }:
let
  palettes = builtins.fromTOML (builtins.readFile ../palette.toml);
  flavors = builtins.attrNames palettes;
  colors = builtins.attrNames palettes.mocha;
  theme = modules: (evalSystem modules).lmx.capabilities.theme;
  chosen = flavor: theme [ { lmx.capabilities.theme.flavor = flavor; } ];
  force =
    { config, ... }:
    {
      assertions = [
        {
          assertion = builtins.deepSeq config.lmx.capabilities.theme true;
          message = "Shared tests: force the theme";
        }
      ];
    };
in
{
  eval = {
    themeDefaults =
      let
        default = theme [ ];
      in
      default.flavor == "mocha" && default.palette == palettes.mocha && builtins.length colors == 26;
    themeFlavors =
      flavors == [
        "frappe"
        "latte"
        "macchiato"
        "mocha"
      ]
      && builtins.all (
        flavor:
        (chosen flavor).palette == palettes.${flavor} && builtins.attrNames palettes.${flavor} == colors
      ) flavors;
  };
  fails = {
    unknownFlavor = {
      modules = [
        { lmx.capabilities.theme.flavor = "espresso"; }
        force
      ];
      message = "lmx.capabilities.theme.flavor' is not of type";
    };
    conflictingFlavors = {
      modules = [
        { lmx.capabilities.theme.flavor = "latte"; }
        { lmx.capabilities.theme.flavor = "mocha"; }
        force
      ];
      message = "lmx.capabilities.theme.flavor' has conflicting definition values";
    };
    readOnlyPalette = {
      modules = [
        { lmx.capabilities.theme.palette.blue = "#000000"; }
        force
      ];
      message = "lmx.capabilities.theme.palette' is read-only";
    };
  };
  # The copy in palette.toml must equal Catppuccin's palette.json that Nixpkgs packages.
  run.themePalette =
    pkgs.runCommand "shared-theme-palette"
      {
        nativeBuildInputs = [ pkgs.jq ];
        copied = builtins.toJSON palettes;
        passAsFile = [ "copied" ];
      }
      ''
        jq -S 'del(.version) | map_values(.colors | map_values(.hex))' \
          ${pkgs.catppuccin}/palette/palette.json > source.json
        jq -S . "$copiedPath" > copied.json
        diff -u source.json copied.json
        touch "$out"
      '';
}
