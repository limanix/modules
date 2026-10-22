{
  config,
  pkgs,
  profile,
  lib,
  name,
  ...
}:
let
  # Login startup rebuilds PATH from /run/current-system/sw. Add the base
  # commands used by global shell setup and assertions to the catalog profile.
  startupProfile = pkgs.buildEnv {
    name = "zsh-startup-profile-${name}";
    paths = [
      profile
      pkgs.coreutils
      pkgs.gnugrep
    ];
  };
  etc = pkgs.runCommandLocal "zsh-smoke-etc-${name}" { } (
    "mkdir -p $out\n"
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList
        (file: entry: ''
          mkdir -p "$out/$(dirname ${lib.escapeShellArg file})"
          ln -s ${entry.source} "$out/${file}"
        '')
        (
          lib.filterAttrs (
            file: _:
            builtins.elem file [
              "zshenv"
              "zshrc"
              "zprofile"
              "zinputrc"
              "atuin/config.toml"
            ]
          ) config.environment.etc
        )
    )
  );
  check = import ./startup-check.nix { inherit config pkgs; };
in
pkgs.runCommand "zsh-startup-smoke-${name}"
  {
    nativeBuildInputs = [
      startupProfile
      pkgs.python3
      pkgs.proot
    ];
    PYTHONPATH = ../../../_shared/test;
    LMX_ZSH = "${pkgs.zsh}/bin/zsh";
    LMX_ETC = etc;
    LMX_PROFILE = startupProfile;
    LMX_CHECK = check;
    TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
  }
  ''
    export HOME="$TMPDIR/home" TERM=xterm-256color
    export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
    mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
    python ${./startup-smoke.py}
    touch "$out"
  ''
