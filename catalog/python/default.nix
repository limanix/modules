{ lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  imports = [ ./selection.nix ];

  lmx.internal.python.versions = lib.mkDefault [ metadata.default ];
}
