{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers)
    profileFor
    verify
    installed
    selectedPackage
    ;
  toolsFor = configuration: line: configuration.config.lmx.internal.terraform.packages.${line};
  valid =
    configuration: line:
    import ./test/check.nix {
      inherit (configuration) config;
      tools = toolsFor configuration line;
      hasPackage = installed configuration;
    };
  lineTests = import ../_shared/test/lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = ./.;
    checkLine = { line, configuration }: valid configuration line;
    runLine =
      { line, configuration }:
      (import ./test/smoke.nix {
        inherit pkgs profileFor;
        profile = profileFor configuration;
        version = line;
        tools = toolsFor configuration line;
        newestTools = toolsFor configuration line;
        allVersionsConfiguration = configuration;
        includeShared = false;
      }).commands;
  };
  inherit (lineTests)
    lines
    configurations
    defaultConfiguration
    allConfiguration
    ;
  newestTools = toolsFor allConfiguration (lib.last lines);
  sharedChecks = import ./test/smoke.nix {
    inherit pkgs profileFor newestTools;
    profile = profileFor allConfiguration;
    version = lib.last lines;
    tools = newestTools;
    allVersionsConfiguration = allConfiguration;
    includeShared = true;
  };
in
{
  eval = lineTests.eval // {
    allLines = verify "Selected lines retain their packages and the newest ordinary commands" (
      builtins.all (line: valid allConfiguration line) lines
      && selectedPackage allConfiguration newestTools.terraform
    ) allConfiguration;
    unfreeDeclaration = builtins.elem "terraform" defaultConfiguration.config.nixpkgs.config.allowUnfreePackages;
  };
  run = lineTests.run // {
    allLines = sharedChecks.coexistence;
  };
  builds = builtins.listToAttrs (
    lib.concatMap (
      line:
      let
        inherit ((toolsFor configurations.${line} line)) terraform;
      in
      [
        {
          name = "terraform-${line}";
          value = terraform;
        }
        {
          name = "terraform-vendor-${line}";
          value = terraform.goModules;
        }
      ]
    ) lines
  );
}
