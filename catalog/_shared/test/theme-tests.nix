{ evalSystem, pkgs }:
let
  themes = builtins.fromTOML (builtins.readFile ../themes.toml);
  terminal = builtins.fromTOML (builtins.readFile ../ansi.toml);
  names = builtins.attrNames themes;
  colorsOf =
    name:
    removeAttrs themes.${name} [
      "dark"
      "title"
      "homepage"
    ];
  roles = builtins.attrNames (colorsOf "catppuccin-mocha");
  theme = modules: (evalSystem modules).lmx.capabilities.theme;
  chosen = name: theme [ { lmx.capabilities.theme.name = name; } ];
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
      default.name == "system"
      && default.palette == colorsOf "catppuccin-mocha"
      && default.dark
      && default.colors == default.ansi
      && builtins.length roles == 18;
    themeTerminal =
      let
        inherit ((theme [ ]).ansi) blue foreground background;
      in
      builtins.attrNames terminal == roles
      && builtins.all (color: color == "default" || builtins.isInt color && color >= 0 && color <= 15) (
        builtins.attrValues terminal
      )
      && blue == 4
      && foreground == null
      && background == null
      && (chosen "tokyo-night").ansi == (theme [ ]).ansi;
    themeNames =
      builtins.length names == 10
      && (chosen "system").palette == colorsOf "catppuccin-mocha"
      && builtins.all (
        name:
        let
          picked = chosen name;
        in
        picked.palette == colorsOf name
        && picked.colors == picked.palette
        && picked.dark == themes.${name}.dark
        && builtins.attrNames (colorsOf name) == roles
      ) names;
  };
  fails = {
    unknownTheme = {
      modules = [
        { lmx.capabilities.theme.name = "espresso"; }
        force
      ];
      message = "lmx.capabilities.theme.name' is not of type";
    };
    conflictingThemes = {
      modules = [
        { lmx.capabilities.theme.name = "nord"; }
        { lmx.capabilities.theme.name = "dracula"; }
        force
      ];
      message = "lmx.capabilities.theme.name' has conflicting definition values";
    };
    readOnlyPalette = {
      modules = [
        { lmx.capabilities.theme.palette.blue = "#000000"; }
        force
      ];
      message = "lmx.capabilities.theme.palette' is read-only";
    };
    readOnlyTerminal = {
      modules = [
        { lmx.capabilities.theme.ansi.blue = 1; }
        force
      ];
      message = "lmx.capabilities.theme.ansi' is read-only";
    };
  };
  run.themePalette =
    pkgs.runCommand "shared-theme-palette"
      {
        nativeBuildInputs = [ pkgs.jq ];
        copied = builtins.toJSON (colorsOf "catppuccin-mocha");
        passAsFile = [ "copied" ];
      }
      ''
        jq -S '.mocha.colors | map_values(.hex) | {
          background: .base, background_dark: .mantle, background_darker: .crust,
          surface: .surface0, selection: .surface1, border: .surface2, muted: .overlay2,
          subtle: .subtext0, foreground: .text, accent: .mauve, red: .red, orange: .peach,
          yellow: .yellow, green: .green, cyan: .teal, blue: .blue, purple: .mauve, pink: .pink
        }' ${pkgs.catppuccin}/palette/palette.json > source.json
        jq -S . "$copiedPath" > copied.json
        diff -u source.json copied.json
        touch "$out"
      '';
}
