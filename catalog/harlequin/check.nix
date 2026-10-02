{ pkgs, hasPackage, ... }:
hasPackage (import ./package.nix { inherit pkgs; })
