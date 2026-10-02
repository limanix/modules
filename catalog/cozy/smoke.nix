{ pkgs, ... }:
{
  project = import ./workspace-smoke.nix { inherit pkgs; };
  playground = import ./playground-smoke.nix { inherit pkgs; };
}
