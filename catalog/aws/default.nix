{ pkgs, pinned, ... }:
let
  # The CLI follows the catalog's nixos-unstable revision: upstream releases it every few days.
  unstable = import ../_shared/lib/source.nix {
    source = "unstable";
    inherit pkgs pinned;
  };
in
{
  imports = [ ./help.nix ];

  lmx.pins = unstable.pins;
  environment.systemPackages = [ unstable.packages.awscli2 ];
}
