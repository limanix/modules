{
  pkgs,
  lib,
  pinned,
  ...
}:
let
  unstable = import ../_shared/lib/source.nix {
    source = "unstable";
    inherit pkgs pinned;
  };
  gcloud = import ./package.nix {
    pkgs = unstable.packages;
    inherit lib;
  };
in
{
  imports = [ ./help.nix ];

  lmx.pins = unstable.pins;
  environment.systemPackages = [ gcloud.package ];
}
