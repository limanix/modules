{ lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  imports = [ ./module.nix ];

  lmx.internal.astronvim.version = lib.mkDefault metadata.default;
}
