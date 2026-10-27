{
  imports = [
    ../gcc/default.nix
    (import ../../_shared/lib/toolchain.nix (import ./toolchain.nix))
  ];
}
