{
  config,
  pkgs,
  tools,
  userName,
  hasPackage,
  ...
}:
let
  warning = "Docker Engine ${tools.docker.version} no longer receives upstream security updates.";
in
config.virtualisation.docker.enable
&& config.virtualisation.docker.package.outPath == tools.docker.outPath
&& builtins.elem "docker" config.users.users.${userName}.extraGroups
&& hasPackage pkgs.lazydocker
&& hasPackage tools.docker
&& builtins.elem "multi-user.target" config.systemd.services.docker.wantedBy
&& builtins.elem "docker.socket" config.systemd.services.docker.requires
&& config.systemd.sockets.docker.socketConfig.SocketGroup == "docker"
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
