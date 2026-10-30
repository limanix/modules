{
  pkgs,
  hasPackage,
  theme,
  ...
}:
hasPackage (import ../package.nix { inherit pkgs theme; })
