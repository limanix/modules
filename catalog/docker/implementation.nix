version:
{
  pinned,
  lib,
  config,
  ...
}:
let
  releases = import ./releases.nix;
  source = releases.sources.${releases.versions.${version}.source};
  tools = import ./packages.nix {
    inherit version pinned;
  };
in
{
  lmx.pins.${source.rev} = source.sha256;
  lmx.internal.docker.packages.${version} = tools;

  virtualisation.docker = {
    enable = true;
    package = tools.docker;
  };

  users.users.${config.limanix.user.name}.extraGroups = [ "docker" ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Docker Engine ${tools.docker.version} no longer receives upstream security updates.";
}
