{
  pkgs,
  version,
  hasPackage,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
builtins.all hasPackage [
  tools.go
  tools.gopls
  tools.delve
  pkgs.gcc
]
