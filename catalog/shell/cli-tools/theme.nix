{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.lmx.capabilities) theme;
  inherit (theme) palette;
  system = theme.name == "system";
  catppuccin = import ../../_shared/lib/catppuccin.nix palette;
  # A template written for Catppuccin Mocha, drawn in the guest's palette by role.
  recolor =
    name: template:
    pkgs.runCommand name
      {
        nativeBuildInputs = [ pkgs.python3 ];
        colors = builtins.toJSON catppuccin;
        passAsFile = [ "colors" ];
      }
      ''
        python3 ${./recolor.py} ${lib.escapeShellArg template} \
          ${pkgs.catppuccin}/palette/palette.json "$colorsPath" > "$out"
      '';
  mocha =
    port:
    pkgs.catppuccin.override {
      variant = "mocha";
      themeList = [ port ];
    };
  batCache = pkgs.runCommand "bat-theme-cache" { nativeBuildInputs = [ pkgs.bat ]; } ''
    mkdir -p source/themes
    ln -s ${recolor "limanix.tmTheme" "${mocha "bat"}/bat/Catppuccin Mocha.tmTheme"} source/themes/limanix.tmTheme
    bat cache --build --source source --target "$out"
  '';
  # delta reads bat's themes only from the bat directory of XDG_CACHE_HOME.
  delta =
    if system then
      pkgs.delta
    else
      pkgs.symlinkJoin {
        name = "delta-${pkgs.delta.version}";
        paths = [ pkgs.delta ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          mkdir -p "$out/share/limanix"
          ln -s ${batCache} "$out/share/limanix/bat"
          wrapProgram "$out/bin/delta" --set XDG_CACHE_HOME "$out/share/limanix"
        '';
      };
  # btop has no setting outside the user's own btop.conf, so its default theme is patched.
  btop = pkgs.btop.overrideAttrs (previous: {
    postPatch = (previous.postPatch or "") + ''
      substituteInPlace src/btop_config.cpp \
        --replace-fail '{"color_theme", "Default"}' '{"color_theme", "${
          if system then "TTY" else "limanix"
        }"}'
    '';
    postInstall =
      (previous.postInstall or "")
      + lib.optionalString (!system) ''
        cp ${recolor "limanix.theme" "${mocha "btop"}/btop/catppuccin_mocha.theme"} "$out/share/btop/themes/limanix.theme"
      '';
  });
  lsColors = pkgs.runCommand "ls-colors" { nativeBuildInputs = [ pkgs.vivid ]; } ''
    vivid generate ${recolor "limanix.yml" "${pkgs.vivid.src}/themes/catppuccin-mocha.yml"} > "$out"
  '';
  channels =
    color:
    map (start: lib.fromHexString (builtins.substring start 2 color)) [
      1
      3
      5
    ];
  sgr = color: "38;2;" + lib.concatMapStringsSep ";" toString (channels color);
  escape = builtins.fromJSON ''"\u001b"'';
  blend =
    color: amount:
    "#"
    + lib.concatMapStrings (
      pair:
      lib.fixedWidthString 2 "0" (
        lib.toLower (lib.toHexString (builtins.floor (pair.fst * amount + pair.snd * (1 - amount) + 0.5)))
      )
    ) (lib.zipLists (channels color) (channels palette.background));
  fzfColors = lib.concatStringsSep "," (
    lib.mapAttrsToList (key: color: "${key}:${color}") {
      "bg+" = catppuccin.surface0;
      bg = catppuccin.base;
      spinner = catppuccin.rosewater;
      hl = catppuccin.red;
      fg = catppuccin.text;
      header = catppuccin.red;
      info = catppuccin.mauve;
      pointer = catppuccin.rosewater;
      marker = catppuccin.lavender;
      "fg+" = catppuccin.text;
      prompt = catppuccin.mauve;
      "hl+" = catppuccin.red;
      selected-bg = catppuccin.surface1;
      border = catppuccin.surface0;
      label = catppuccin.text;
    }
  );
  ezaColors = lib.concatStringsSep ":" (
    lib.mapAttrsToList (key: color: "${key}=${sgr color}") {
      ur = palette.yellow;
      uw = palette.red;
      ux = palette.green;
      ue = palette.green;
      gr = palette.yellow;
      gw = palette.red;
      gx = palette.green;
      tr = palette.yellow;
      tw = palette.red;
      tx = palette.green;
      su = palette.purple;
      sf = palette.purple;
      xa = palette.muted;
      sn = palette.green;
      sb = palette.green;
      df = palette.green;
      ds = palette.green;
      uu = palette.yellow;
      uR = palette.red;
      un = palette.subtle;
      gu = palette.yellow;
      gR = palette.red;
      gn = palette.subtle;
      lc = palette.red;
      lm = palette.red;
      ga = palette.green;
      gm = palette.blue;
      gd = palette.red;
      gv = palette.yellow;
      gt = palette.purple;
      gi = palette.muted;
      gc = palette.red;
      xx = palette.muted;
      da = palette.blue;
      "in" = palette.purple;
      bl = palette.cyan;
      hd = palette.foreground;
      lp = palette.cyan;
      cc = palette.red;
    }
  );
  ripgrep =
    color:
    lib.concatMapStringsSep "," (start: "0x" + builtins.substring start 2 color) [
      1
      3
      5
    ];
  ripgrepConfig = pkgs.writeText "ripgrep-colors" ''
    --colors=path:fg:${ripgrep palette.purple}
    --colors=line:fg:${ripgrep palette.green}
    --colors=column:fg:${ripgrep palette.muted}
    --colors=match:fg:${ripgrep palette.red}
    --colors=match:style:bold
  '';
  tealdeer =
    color:
    let
      inherit (lib) elemAt;
      values = channels color;
    in
    "{ rgb = { r = ${toString (elemAt values 0)}, g = ${toString (elemAt values 1)}, b = ${toString (elemAt values 2)} } }";
  tealdeerConfig = pkgs.writeTextDir "config.toml" ''
    [style.description]
    foreground = ${tealdeer palette.foreground}

    [style.command_name]
    foreground = ${tealdeer palette.accent}
    bold = true

    [style.example_text]
    foreground = ${tealdeer palette.green}

    [style.example_code]
    foreground = ${tealdeer palette.cyan}

    [style.example_variable]
    foreground = ${tealdeer palette.cyan}
    underline = true
  '';
in
{
  environment = {
    systemPackages = [
      delta
      btop
    ];

    variables = lib.mapAttrs (_: lib.mkDefault) (
      {
        FZF_DEFAULT_OPTS = "--color=${if system then "16" else fzfColors}";
      }
      // (
        # With the system theme bat, and delta through it, highlight in the terminal's colors.
        if system then
          { BAT_THEME = "ansi"; }
        else
          {
            BAT_THEME = "limanix";
            BAT_CACHE_PATH = "${batCache}";
            EZA_COLORS = ezaColors;
            JQ_COLORS = lib.concatMapStringsSep ":" (role: sgr palette.${role}) [
              "orange"
              "orange"
              "orange"
              "orange"
              "green"
              "muted"
              "muted"
              "blue"
            ];
            RIPGREP_CONFIG_PATH = "${ripgrepConfig}";
            TEALDEER_CONFIG_DIR = "${tealdeerConfig}";
            GROFF_NO_SGR = "1";
            LESS_TERMCAP_md = "${escape}[1;${sgr palette.accent}m";
            LESS_TERMCAP_me = "${escape}[0m";
            LESS_TERMCAP_us = "${escape}[4;${sgr palette.green}m";
            LESS_TERMCAP_ue = "${escape}[0m";
            LESS_TERMCAP_so = "${escape}[${sgr palette.background};48;2;${
              lib.concatMapStringsSep ";" toString (channels palette.accent)
            }m";
            LESS_TERMCAP_se = "${escape}[0m";
          }
      )
    );

    extraInit = lib.mkIf (!system) ''
      IFS= read -r LS_COLORS < ${lsColors}
      export LS_COLORS
    '';
  };

  programs.git.config = lib.mkMerge [
    {
      core.pager = lib.mkDefault "${delta}/bin/delta";
      interactive.diffFilter = lib.mkDefault "${delta}/bin/delta --color-only";
    }
    (lib.mkIf (!system) {
      delta = lib.mapAttrs (_: lib.mkDefault) (
        {
          minus-style = "syntax ${blend palette.red 0.1}";
          minus-emph-style = "bold syntax ${blend palette.red 0.25}";
          plus-style = "syntax ${blend palette.green 0.1}";
          plus-emph-style = "bold syntax ${blend palette.green 0.25}";
          line-numbers-minus-style = palette.red;
          line-numbers-plus-style = palette.green;
          line-numbers-zero-style = palette.muted;
          line-numbers-left-style = palette.border;
          line-numbers-right-style = palette.border;
          file-style = palette.foreground;
          file-decoration-style = palette.border;
          hunk-header-decoration-style = palette.border;
          hunk-header-line-number-style = palette.subtle;
        }
        // (if theme.dark then { dark = true; } else { light = true; })
      );
      color = lib.mapAttrsRecursive (_: lib.mkDefault) {
        branch = {
          current = "${palette.accent} bold";
          local = palette.foreground;
          remote = palette.green;
        };
        status = {
          added = palette.green;
          changed = palette.yellow;
          untracked = palette.red;
          branch = "${palette.accent} bold";
          nobranch = palette.red;
          header = palette.muted;
        };
        decorate = {
          HEAD = "${palette.accent} bold";
          branch = palette.green;
          remoteBranch = palette.red;
          tag = palette.yellow;
          stash = palette.purple;
        };
        diff = {
          meta = palette.muted;
          frag = palette.purple;
          commit = palette.yellow;
          old = palette.red;
          new = palette.green;
        };
        grep = {
          filename = palette.purple;
          linenumber = palette.green;
          match = "${palette.red} bold";
        };
        interactive = {
          prompt = palette.accent;
          header = palette.muted;
          help = palette.muted;
          error = palette.red;
        };
      };
    })
  ];
}
