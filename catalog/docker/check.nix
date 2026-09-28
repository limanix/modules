{
  config,
  pkgs,
  version,
  userName,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
config.virtualisation.docker.enable
&& config.virtualisation.docker.package.outPath == tools.docker.outPath
&& builtins.elem "docker" config.users.users.${userName}.extraGroups
