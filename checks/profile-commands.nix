{
  pkgs,
  evaluate,
  directory,
  commands,
}:
let
  metadata = builtins.fromTOML (builtins.readFile (directory + "/module.toml"));
  versions = builtins.sort pkgs.lib.versionOlder metadata.versions;
  configuration = evaluate (map (version: directory + "/versions/${version}.nix") versions);
  newest = import (directory + "/packages.nix") {
    version = pkgs.lib.last versions;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
pkgs.runCommand "${builtins.baseNameOf directory}-coexisting-profile-commands" { } (
  pkgs.lib.concatStringsSep "\n" (
    pkgs.lib.mapAttrsToList (command: package: ''
      test "$(readlink -f ${configuration.config.system.path}/bin/${command})" = \
        "$(readlink -f ${newest.${package}}/bin/${command})"
    '') commands
  )
  + "\ntouch $out\n"
)
