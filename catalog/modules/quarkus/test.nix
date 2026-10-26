{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate installed profileFor;
  quarkus =
    configuration: pkgs.quarkus.override { jdk = configuration.config.lmx.capabilities.jdk.package; };
  configuration = evaluate [ ./default.nix ];
  java25 = evaluate [
    ./default.nix
    ../../toolchains/java/versions/25.nix
  ];
  smoke =
    label: configuration:
    pkgs.runCommand label { } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      launcher="$(readlink -f ${profileFor configuration}/bin/quarkus)"
      grep -F '${configuration.config.lmx.capabilities.jdk.package}/bin/java' "$launcher"
      timeout 60 ${profileFor configuration}/bin/quarkus --version | tee "$out"
      grep -F '${pkgs.quarkus.version}' "$out"
    '';
in
{
  eval = {
    package = installed configuration (quarkus configuration);
    java25 = installed java25 (quarkus java25);
  };
  run = {
    commands = smoke "quarkus-commands" configuration;
    java25 = smoke "quarkus-on-java-25" java25;
  };
  builds = {
    default = quarkus configuration;
    java25 = quarkus java25;
  };
}
