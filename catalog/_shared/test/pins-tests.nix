{ evalSystem, lib }:
let
  loader = import ../lib/pinned.nix;
  empty = loader {
    sources = { };
    system = throw "Empty pins forced platform";
  };
  unused = loader {
    sources.unused = throw "Unused pin was forced";
    system = throw "Unused pins forced platform";
    unfreePackages = throw "Unused pins forced policy";
  };
  probe = { pinned, ... }: {
    options.sharedTestPinNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
    };
    config.sharedTestPinNames = builtins.attrNames pinned;
  };
  wiring = evalSystem [ probe ];
  unstable = builtins.fromTOML (builtins.readFile ../unstable.toml);
  platform = { unstableSource, ... }: {
    options.sharedTestUnstable = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      internal = true;
    };
    config = {
      sharedTestUnstable = unstableSource;
      lmx.pins.${unstableSource.rev} = unstableSource.sha256;
    };
  };
  unstableWiring = evalSystem [ platform ];
  declarations =
    (lib.evalModules {
      modules = [
        ../pins.nix
        { lmx.pins.source = "same hash"; }
        { lmx.pins.source = "same hash"; }
      ];
    }).config.lmx.pins;
in
{
  eval = {
    emptyPins = empty == { };
    lazyPins = builtins.attrNames unused == [ "unused" ];
    pinDeclarations = declarations == { source = "same hash"; };
    pinWiring = wiring.lmx.pins == { } && wiring.sharedTestPinNames == [ ];
    unstableSource =
      unstableWiring.sharedTestUnstable == {
        inherit (unstable) rev sha256;
      }
      && builtins.match "[0-9a-f]{40}" unstable.rev != null
      && unstableWiring.lmx.pins == { ${unstable.rev} = unstable.sha256; };
  };
  fails.conflictingPins = {
    modules = [
      { lmx.pins.source = "first hash"; }
      { lmx.pins.source = "second hash"; }
      ({ config, ... }: {
        assertions = [
          {
            assertion = builtins.deepSeq config.lmx.pins.source true;
            message = "Shared tests: force source hashes";
          }
        ];
      })
    ];
    message = "lmx.pins.source' has conflicting definition values";
  };
}
