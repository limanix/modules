{
  sources,
  system,
  unfreePackages ? [ ],
}:
builtins.mapAttrs (
  rev: sha256:
  let
    source = builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
      inherit sha256;
    };
    lib = import (source + "/lib");
  in
  import source {
    inherit system;
    overlays = [ ];
    config.allowUnfreePredicate = package: builtins.elem (lib.getName package) unfreePackages;
  }
) sources
