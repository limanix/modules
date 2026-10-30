# The previews that the site shows, saved as SVG with JSON about them: each theme drawn on tmux,
# Neovim, eza and delta from the catalog, and each prompt in a Git repository.
let
  nixpkgs = import ../checks/nixpkgs.nix;
  system = builtins.currentSystem;
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;
  themes = builtins.fromTOML (builtins.readFile ../catalog/_shared/themes.toml);
  theme =
    name:
    let
      inherit
        (
          (import ../checks/nixos.nix {
            inherit nixpkgs system;
            userName = "preview";
            modules = [
              ../catalog/shell/tmux/default.nix
              ../catalog/shell/neovim/default.nix
              ../catalog/shell/cli-tools/default.nix
              { lmx.capabilities.theme.name = name; }
            ];
          })
        )
        config
        ;
      delta = lib.findFirst (
        package: lib.hasPrefix "delta-" (package.name or "")
      ) pkgs.delta config.environment.systemPackages;
    in
    {
      inherit name;
      tmux = config.environment.etc."tmux.conf".source;
      environment = config.system.build.setEnvironment;
      gitconfig = config.environment.etc."gitconfig".source;
      neovim = "${config.programs.neovim.finalPackage}/bin/nvim";
      delta = "${delta}/bin/delta";
      palette = config.lmx.capabilities.theme.palette;
      inherit (themes.${name}) title homepage dark;
    };
  shellDirectory = ../catalog/shell;
  metadataOf = name: builtins.fromTOML (builtins.readFile (shellDirectory + "/${name}/module.toml"));
  prompts = builtins.filter (name: metadataOf name ? prompt) (
    builtins.attrNames (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir shellDirectory)
    )
  );
  prompt =
    name:
    let
      metadata = metadataOf name;
      inherit (metadata.prompt) shells;
      shell = if builtins.elem "zsh" shells then "zsh" else "bash";
      inherit
        (
          (import ../checks/nixos.nix {
            inherit nixpkgs system;
            userName = "preview";
            modules = lib.optional (shell == "zsh") ../catalog/shell/zsh/default.nix ++ [
              (shellDirectory + "/${name}/default.nix")
              { lmx.capabilities.theme.name = "catppuccin-mocha"; }
            ];
          })
        )
        config
        ;
    in
    {
      inherit name shell shells;
      inherit (metadata) description;
      inherit (config.limanix.help.${name}) title;
      init = config.programs.${shell}.promptInit;
      shellPath = if shell == "zsh" then "${pkgs.zsh}/bin/zsh" else "${pkgs.bashInteractive}/bin/bash";
      xdg = lib.mapAttrs (_: entry: entry.source) (
        lib.filterAttrs (file: _: file == "liquidpromptrc") config.environment.etc
      );
      palette = config.lmx.capabilities.theme.palette;
    };
in
pkgs.runCommand "catalog-previews"
  {
    nativeBuildInputs = [
      (pkgs.python3.withPackages (python: [ python.pyte ]))
      pkgs.tmux
      pkgs.git
      pkgs.eza
      pkgs.ncurses
      pkgs.proot
    ];
    themes = builtins.toJSON (map theme (builtins.attrNames themes));
    prompts = builtins.toJSON (map prompt prompts);
    passAsFile = [
      "themes"
      "prompts"
    ];
  }
  ''
    export TERMINFO_DIRS=${pkgs.ncurses}/share/terminfo
    python3 ${./previews.py} "$themesPath" "$promptsPath" "$out"
  ''
