{ pkgs, lib, ... }:
let
  gcloud = import ./package.nix { inherit pkgs lib; };
in
{
  imports = [ ./help.nix ];

  environment.systemPackages = [ gcloud.package ];
}
