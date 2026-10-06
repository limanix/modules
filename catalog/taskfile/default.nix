{ lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  imports = [ ./selection.nix ];

  lmx.internal.taskfile.versions = lib.mkDefault [ metadata.default ];
}
