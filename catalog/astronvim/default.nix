{ lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  imports = [ ./module.nix ];

  lmx.internal.astronvim.versions = lib.mkDefault [ metadata.default ];
}
