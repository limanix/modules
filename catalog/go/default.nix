{ lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  imports = [ ./selection.nix ];

  lmx.internal.go.versions = lib.mkDefault [ metadata.default ];
}
