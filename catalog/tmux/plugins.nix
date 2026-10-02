{ pkgs }:
let
  # The pinned plugins retain /usr/bin/env shebangs without a runtime Bash input.
  withBash =
    plugin:
    plugin.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.bash ];
      postInstall = (old.postInstall or "") + ''
        patchShebangs --host "$out/share/tmux-plugins"
      '';
    });
in
map withBash [
  pkgs.tmuxPlugins.resurrect
  pkgs.tmuxPlugins.continuum
]
