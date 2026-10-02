{
  lib,
  pkgs,
  system,
}:
let
  versions = [
    "1"
    "2"
  ];
  module = {
    name = "example";
    version = "2";
    path = "/fixture/default.nix";
    smoke = ./fixtures/smoke-selection.nix;
    variants = map (version: {
      inherit version;
      name = "example-${version}";
      path = "/fixture/${version}.nix";
    }) versions;
  };
  configuration = {
    inherit pkgs;
    config = { };
  };
  context = {
    inherit module lib system;
    defaultConfiguration = configuration;
    allVersionsConfiguration = configuration;
    configurations = { };
    versionConfigurations = builtins.listToAttrs (
      map (name: {
        inherit name;
        value = configuration;
      }) versions
    );
    profileFor = _: null;
  };
  checks = overrides: map (check: check.name) (import ./module-smoke.nix (context // overrides));
  shared = checks { defaultVersionEquivalent = true; };
  distinct = checks { defaultVersionEquivalent = false; };
  startup = checks {
    module = module // {
      smoke = ./fixtures/smoke-startup.nix;
    };
  };
  pr = checks {
    runtimeProfile = "pr";
    allVersionsConfiguration = throw "PR must not instantiate historical coexistence";
  };
  prOlder = checks {
    runtimeProfile = "pr";
    runtimeVersions = [ "1" ];
    allVersionsConfiguration = throw "PR must not instantiate historical coexistence";
  };
  prStartup = checks {
    runtimeProfile = "pr";
    runtimeVersions = [ "1" ];
    module = module // {
      smoke = ./fixtures/smoke-startup.nix;
    };
  };
  scopedContext = {
    runtimeProfile = "pr";
    configurations.providerOverride = throw "PR must not force the all-version provider fixture";
    defaultConfiguration = configuration // {
      config.fixturePath = module.path;
    };
    versionConfigurations = builtins.listToAttrs (
      map (selected: {
        name = selected.version;
        value = configuration // {
          config.fixturePath = selected.path;
        };
      }) module.variants
    );
    runtimeConfigurationsFor = selected: {
      selectedPath = selected.path;
      providerOverride =
        assert
          selected.path == module.path && selected.version == module.version
          || builtins.any (
            variant: variant.path == selected.path && variant.version == selected.version
          ) module.variants;
        null;
    };
  };
  scopedPr = checks scopedContext;
  scopedOlder = checks (scopedContext // { runtimeVersions = [ "1" ]; });
  rejects = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  selection = arguments: import ./runtime-selection.nix ({ modules = [ module ]; } // arguments);
  unversioned = checks {
    module = module // {
      variants = [ ];
      version = null;
    };
  };
in
assert
  shared == [
    "contract-commands-example-1"
    "contract-commands-example-2"
    "contract-coexistence"
    "contract-configuration"
  ];
assert distinct == shared ++ [ "contract-commands-example" ];
assert
  startup == [
    "contract-startup-example-1"
    "contract-startup-example-2"
    "contract-startup-example"
  ];
assert
  unversioned == [
    "contract-coexistence"
    "contract-commands-example"
    "contract-configuration"
  ];
assert
  pr == [
    "contract-commands-example"
    "contract-configuration"
  ];
assert prOlder == pr ++ [ "contract-commands-example-1" ];
assert
  prStartup == [
    "contract-startup-example"
    "contract-startup-example-1"
  ];
assert
  checks {
    runtimeProfile = "all";
    defaultVersionEquivalent = true;
  } == shared;
assert scopedPr == pr;
assert scopedOlder == prOlder;
# Full coverage must keep its canonical fixtures and never force the PR hook.
assert
  checks {
    runtimeProfile = "all";
    defaultVersionEquivalent = true;
    runtimeConfigurationsFor = throw "Full runtime must not evaluate the scoped fixture hook";
  } == shared;
assert rejects (checks (scopedContext // { runtimeConfigurationsFor = { }; }));
assert rejects (checks (scopedContext // { runtimeConfigurationsFor = _: [ ]; }));
assert rejects (
  checks (
    scopedContext
    // {
      runtimeConfigurationsFor = _: { selectedPath = "/fixture/wrong.nix"; };
    }
  )
);
assert rejects (selection {
  profile = "unknown";
});
assert rejects (selection {
  profile = "all";
  versions = [ "1" ];
});
assert rejects (selection {
  versions = "1";
});
assert rejects (selection {
  versions = [ 1 ];
});
assert rejects (selection {
  profile = "pr";
  versions = [
    "1"
    "1"
  ];
});
assert rejects (selection {
  profile = "pr";
  versions = [ "3" ];
});
assert rejects (selection {
  profile = "pr";
  versions = [ "1" ];
  modules = [
    module
    module
  ];
});
assert rejects (selection {
  profile = "pr";
  versions = [ "1" ];
  modules = [ ];
});
assert rejects (checks {
  runtimeProfile = "pr";
  runtimeVersions = [ "3" ];
});
assert
  checks {
    module = module // {
      smoke = null;
    };
  } == [ ];
true
