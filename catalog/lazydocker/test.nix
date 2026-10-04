{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate installed;
  configuration = evaluate [ ./default.nix ];
  profile = helpers.profileFor configuration;
in
{
  eval = {
    package = installed configuration pkgs.lazydocker;
    noDocker = !configuration.config.virtualisation.docker.enable;
  };
  run = import ./test/run.nix { inherit pkgs profile; };
}
