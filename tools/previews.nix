# The preview of each theme that the site shows: tmux, Neovim, eza and delta from the catalog,
# drawn with the theme in a terminal and saved as SVG, with the themes' palettes as JSON.
let
  nixpkgs = import ../checks/nixpkgs.nix;
  system = builtins.currentSystem;
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;
  themes = builtins.fromTOML (builtins.readFile ../catalog/_shared/themes.toml);
  scene =
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
in
pkgs.runCommand "theme-previews"
  {
    nativeBuildInputs = [
      (pkgs.python3.withPackages (python: [ python.pyte ]))
      pkgs.tmux
      pkgs.git
      pkgs.eza
      pkgs.ncurses
    ];
    scenes = builtins.toJSON (map scene (builtins.attrNames themes));
    passAsFile = [ "scenes" ];
  }
  ''
    export TERMINFO_DIRS=${pkgs.ncurses}/share/terminfo
    python3 ${./previews.py} "$scenesPath" "$out"
  ''
