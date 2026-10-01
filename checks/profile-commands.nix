{
  pkgs,
  profile,
  directory,
  commands,
}:
let
  metadata = builtins.fromTOML (builtins.readFile (directory + "/module.toml"));
  versions = builtins.sort pkgs.lib.versionOlder metadata.versions;
  newest = import (directory + "/packages.nix") {
    version = pkgs.lib.last versions;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
pkgs.runCommand "${builtins.baseNameOf directory}-coexisting-profile-commands" { } (
  pkgs.lib.concatStringsSep "\n" (
    pkgs.lib.mapAttrsToList (command: package: ''
      test "$(readlink -f ${profile}/bin/${command})" = \
        "$(readlink -f ${newest.${package}}/bin/${command})"
    '') commands
  )
  + "\ntouch $out\n"
)
