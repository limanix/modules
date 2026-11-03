# Used by `harness drift` to compare release maps with the base and unstable pins.
let
  catalog = ../catalog;
  lock = (builtins.fromJSON (builtins.readFile ../flake.lock)).nodes.nixpkgs;
  unstableRevision = builtins.fromTOML (builtins.readFile (catalog + "/_shared/unstable.toml"));

  sources = {
    base = import ../checks/nixpkgs.nix;
    unstable = builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${unstableRevision.rev}.tar.gz";
      inherit (unstableRevision) sha256;
    };
  };
  lib = import (sources.base + "/lib");
  sets = builtins.mapAttrs (
    _: source:
    import source {
      system = builtins.currentSystem;
      overlays = [ ];
      config = {
        allowAliases = false;
        allowUnfree = true;
      };
    }
  ) sources;

  analyze = import ./drift-analysis.nix { inherit lib sets; };
  findingsOf =
    module:
    analyze {
      inherit (module) name;
      records = import (module.directory + "/releases.nix");
    };

  hasReleaseMap =
    module:
    let
      file = module.directory + "/releases.nix";
    in
    builtins.pathExists file
    && builtins.all (record: record ? source) (builtins.attrValues (import file));
  modules = builtins.filter hasReleaseMap (import ../checks/catalog.nix catalog);

in
{
  findings = builtins.concatMap findingsOf modules;
  base = {
    inherit (lock.locked) rev;
    inherit (lock.original) ref;
  };
  unstable = unstableRevision.rev;
}
