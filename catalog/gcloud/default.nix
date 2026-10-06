{ pkgs, lib, ... }:
let
  gcloud = import ./package.nix { inherit pkgs lib; };
in
{
  environment.systemPackages = [ gcloud.package ];
}
