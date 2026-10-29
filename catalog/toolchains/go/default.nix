{ pkgs, pinned, ... }:
let
  unstable = import ../../_shared/lib/source.nix {
    source = "unstable";
    inherit pkgs pinned;
  };
in
{
  imports = [ (import ../../_shared/lib/toolchain.nix (import ./toolchain.nix)) ];

  lmx.pins = unstable.pins;
}
