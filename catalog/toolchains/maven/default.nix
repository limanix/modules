{
  imports = [
    ../java/default.nix
    (import ../../_shared/lib/lines.nix (import ./lines.nix))
  ];
}
