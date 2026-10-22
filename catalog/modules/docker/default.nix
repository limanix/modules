{ lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  imports = [ ./selection.nix ];

  lmx.internal.docker.versions = lib.mkDefault [ metadata.default ];
}
