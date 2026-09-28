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
  tools.rustc
  tools.cargo
  tools.rustfmt
  tools.clippy
  tools.rust-analyzer
  pkgs.gcc
  pkgs.pkg-config
  pkgs.gdb
]
