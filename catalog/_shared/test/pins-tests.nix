{ evalSystem, lib }:
let
  # Use the real loader with a poisoned unused value: forcing it must fail
  # before any fetch can be attempted. No synthetic source is downloaded.
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
