{ config, pkgs, ... }:
{
  commands = pkgs.runCommand "docker-commands" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    ${config.virtualisation.docker.package}/bin/docker --version > "$out"
    ${config.virtualisation.docker.package}/bin/docker compose version >> "$out"
    test -s "$out"
  '';
}
