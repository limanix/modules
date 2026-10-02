{ pkgs, ... }:
{
  project = import ./workspace-smoke.nix { inherit pkgs; };
}
