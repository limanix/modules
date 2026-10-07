{
  config,
  pkgs,
  lib,
  ...
}:
let
  colors = config.lmx.capabilities.theme.palette;
  names = [
    "black"
    "white"
    "gray"
    "darkgray"
    "red"
    "lightred"
    "green"
    "lightgreen"
    "yellow"
    "lightyellow"
    "blue"
    "magenta"
    "lightmagenta"
    "cyan"
    "lightcyan"
  ];
  values = with colors; [
    base
    text
    subtext0
    surface2
    red
    red
    green
    green
    yellow
    yellow
    blue
    mauve
    mauve
    sky
    sky
  ];
  themeText = lib.replaceStrings ((map (name: ''"${name}"'') names) ++ [ "overall = {}" ]) (
    (map (value: ''"${value}"'') values) ++ [ ''overall = { bg = "${colors.base}" }'' ]
  ) (builtins.readFile ./theme-default.toml);
  theme = builtins.fromTOML themeText;
  themeFile = pkgs.writeText "yazi-theme.toml" themeText;
  defaultConfiguration = pkgs.runCommandLocal "yazi-default-configuration" { } ''
    mkdir -p "$out"
    ln -s ${themeFile} "$out/theme.toml"
  '';
  package =
    lib.makeOverridable
      (
        arguments:
        let
          settings = lib.filterAttrs (_: value: value != { }) arguments.settings;
          managed =
            settings != { }
            || arguments.initLua != null
            || arguments.plugins != { }
            || arguments.flavors != { };
          usesFlavor = builtins.any (value: value != "") (builtins.attrValues (settings.theme.flavor or { }));
          configuredTheme = settings.theme or { };
          upstream = pkgs.yazi.override (
            arguments
            // {
              # These builders generate configuration links and command wrappers only.
              runCommand = pkgs.runCommandLocal;
              settings =
                if managed then
                  settings
                  // {
                    theme = if usesFlavor then configuredTheme else lib.recursiveUpdate theme configuredTheme;
                  }
                else
                  { };
            }
          );
          command = pkgs.writeShellScript "yazi-with-default-theme" ''
            limanix_yazi_command=${lib.escapeShellArg "${upstream}/bin/yazi"}
            limanix_yazi_configuration=${lib.escapeShellArg (toString defaultConfiguration)}
            limanix_yazi_theme=${lib.escapeShellArg (toString themeFile)}
            limanix_yazi_mktemp=${lib.escapeShellArg "${pkgs.coreutils}/bin/mktemp"}
            limanix_yazi_ln=${lib.escapeShellArg "${pkgs.coreutils}/bin/ln"}
            limanix_yazi_rm=${lib.escapeShellArg "${pkgs.coreutils}/bin/rm"}
            ${builtins.readFile ./theme-wrapper.sh}
          '';
        in
        if managed then
          upstream
        else
          pkgs.runCommandLocal upstream.name
            {
              inherit (upstream) pname version meta;
            }
            ''
              mkdir -p "$out/bin"
              ln -s ${upstream}/share "$out/share"
              ln -s ${upstream}/bin/ya "$out/bin/ya"
              ln -s ${command} "$out/bin/yazi"
            ''
      )
      {
        settings = { };
        initLua = null;
        plugins = { };
        flavors = { };
        inherit (pkgs) yazi-unwrapped;
      };
  shellInit = builtins.readFile ./shell-init.sh;
in
{
  programs = {
    yazi = {
      enable = true;
      package = lib.mkDefault package;
    };
    bash.interactiveShellInit = shellInit;
    zsh.interactiveShellInit = shellInit;
  };
}
