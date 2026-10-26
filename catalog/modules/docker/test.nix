{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) profileFor installed;
  lineTests = import ../../_shared/test/lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = ./.;
    checkLine =
      { line, configuration }:
      let
        inherit (configuration) config;
        tools = config.lmx.internal.docker.packages.${line};
        warning = "Docker Engine ${tools.docker.version} no longer receives upstream security updates.";
      in
      config.virtualisation.docker.enable
      && config.virtualisation.docker.package.outPath == tools.docker.outPath
      && builtins.elem "docker" config.users.users.${config.limanix.user.name}.extraGroups
      && installed configuration pkgs.lazydocker
      && installed configuration tools.docker
      && builtins.elem "multi-user.target" config.systemd.services.docker.wantedBy
      && builtins.elem "docker.socket" config.systemd.services.docker.requires
      && config.systemd.sockets.docker.socketConfig.SocketGroup == "docker"
      && (builtins.elem warning config.warnings == (tools.endOfLife == true));
    runLine =
      { configuration, ... }:
      pkgs.runCommand "docker-commands" { } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        ${profileFor configuration}/bin/docker --version > "$out"
        ${profileFor configuration}/bin/docker compose version >> "$out"
        test -s "$out"
      '';
  };
in
{
  inherit (lineTests) eval run;
  fails.twoLines = {
    modules = map (line: ./versions + "/${line}.nix") lineTests.lines;
    message = "docker: select one line";
  };
}
