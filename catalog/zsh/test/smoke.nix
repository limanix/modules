{
  config,
  pkgs,
  profile,
  lib,
  ...
}:
let
  # Login startup rebuilds PATH from /run/current-system/sw. Add the base
  # commands used by global shell setup and assertions to the catalog profile.
  startupProfile = pkgs.buildEnv {
    name = "zsh-startup-profile";
    paths = [
      profile
      pkgs.coreutils
      pkgs.gnugrep
    ];
  };
  etc = pkgs.runCommandLocal "zsh-smoke-etc" { } (
    "mkdir -p $out\n"
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList
        (name: entry: ''
          mkdir -p "$out/$(dirname ${lib.escapeShellArg name})"
          ln -s ${entry.source} "$out/${name}"
        '')
        (
          lib.filterAttrs (
            name: _:
            builtins.elem name [
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
{
  startup =
    pkgs.runCommand "zsh-startup-smoke"
      {
        nativeBuildInputs = [
          startupProfile
          pkgs.python3
          pkgs.proot
        ];
        PYTHONPATH = ../../_shared/test;
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
      '';
}
