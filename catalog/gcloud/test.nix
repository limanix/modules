{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  gcloud = import ./package.nix { inherit pkgs lib; };
  configuration = helpers.evaluate [ ./default.nix ];
  empty = helpers.evaluate [ ];
  startup =
    record:
    let
      cfg = record.config;
      paths = [
        (toString cfg.system.build.etc)
      ]
      ++ lib.optional (
        cfg.systemd.services ? dbus-broker
      ) cfg.systemd.services.dbus-broker.unitConfig."X-Restart-Triggers";
    in
    lib.replaceStrings paths (map (_: "<generated-configuration>") paths) (
      builtins.toJSON {
        units = builtins.mapAttrs (_: unit: { inherit (unit) enable text; }) cfg.systemd.units;
        activation = cfg.system.activationScripts.script;
      }
    );
in
{
  eval = {
    package =
      helpers.installed configuration gcloud.package
      && builtins.all (
        candidate: helpers.installed empty candidate || toString candidate == toString gcloud.package
      ) configuration.config.environment.systemPackages;
    noStartup = startup configuration == startup empty;
  };
  run = import ./test/run.nix {
    inherit pkgs;
    profile = helpers.profileFor configuration;
  };
  builds = builtins.listToAttrs (
    map (derivation: {
      name = lib.getName derivation;
      value = derivation;
    }) gcloud.localBuilds
  );
}
