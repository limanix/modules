{ profile, pkgs, ... }:
{
  commands = pkgs.runCommand "docker-commands" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    ${profile}/bin/docker --version > "$out"
    ${profile}/bin/docker compose version >> "$out"
    test -s "$out"
  '';
}
