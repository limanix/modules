# Pure loader for one evaluation's declared sources and effective policy.
# Values stay lazy; selecting one revision does not import the other sources.
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
    # Read the library directly. Resolving it through a configured package set
    # could make the unfree predicate depend on the package it must validate.
    lib = import (source + "/lib");
  in
  import source {
    inherit system;
    overlays = [ ];
    config.allowUnfreePredicate = package: builtins.elem (lib.getName package) unfreePackages;
  }
) sources
