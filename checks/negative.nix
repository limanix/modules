{ system }:
let
  nixpkgs = import ./nixpkgs.nix;
  configurationFor =
    modules:
    import ./nixos.nix {
      inherit nixpkgs system modules;
      userName = "module-check";
    };
  catalog = import ./catalog.nix ../catalog;
  docker = builtins.head (builtins.filter (module: module.name == "docker") catalog);
  dockerConfiguration = configurationFor (
    map (variant: variant.path) [
      (builtins.elemAt docker.variants 0)
      (builtins.elemAt docker.variants 1)
    ]
  );
  conflictingTools = configurationFor [
    ({ lib, pkgs, ... }: {
      lmx.capabilities.editor.tools.example = lib.mkOverride 1000 {
        package = pkgs.hello;
        command = "${pkgs.hello}/bin/hello";
      };
    })
    ({ lib, pkgs, ... }: {
      lmx.capabilities.editor.tools.example = lib.mkOverride 1000 {
        package = pkgs.coreutils;
        command = "${pkgs.coreutils}/bin/true";
      };
    })
  ];
  conflictingToolFields =
    values:
    configurationFor (
      map (fields: { lib, pkgs, ... }: {
        lmx.capabilities.editor.tools.example = lib.mkOverride 1000 (
          {
            package = pkgs.hello;
            command = "${pkgs.hello}/bin/hello";
          }
          // fields
        );
      }) values
    );
  missingPackage = configurationFor [
    {
      lmx.capabilities.editor.tools.example.command = "/example";
    }
  ];
  missingCommand = configurationFor [
    ({ pkgs, ... }: {
      lmx.capabilities.editor.tools.example.package = pkgs.hello;
    })
  ];
  missingParsers = configurationFor [
    {
      lmx.capabilities.editor.languages.example = { };
    }
  ];
in
{
  requiredSmoke = {
    expected = "example: custom builds or program configuration require smoke.nix";
    actual = builtins.deepSeq (import ./catalog.nix ./fixtures/smoke-required) true;
  };
  dockerVersionConflict = {
    expected = "conflicting definition values";
    actual = dockerConfiguration.config.virtualisation.docker.package.outPath;
  };
  equalToolPrecedence = {
    expected = "lmx.capabilities.editor.tools.example' has conflicting definition values";
    actual = conflictingTools.config.lmx.capabilities.editor.tools.example.command;
  };
  equalToolPrecedenceArgs = {
    expected = "lmx.capabilities.editor.tools.example' has conflicting definition values";
    actual =
      (conflictingToolFields [
        {
          args = [
            "--mode"
            "a"
          ];
        }
        {
          args = [
            "--mode"
            "b"
          ];
        }
      ]).config.lmx.capabilities.editor.tools.example.args;
  };
  equalToolPrecedenceLanguages = {
    expected = "lmx.capabilities.editor.tools.example' has conflicting definition values";
    actual =
      (conflictingToolFields [
        { languages = [ "go" ]; }
        { languages = [ "rust" ]; }
      ]).config.lmx.capabilities.editor.tools.example.languages;
  };
  equalToolPrecedenceDefaultArgs = {
    expected = "lmx.capabilities.editor.tools.example' has conflicting definition values";
    actual =
      (conflictingToolFields [
        { }
        {
          args = [
            "--mode"
            "a"
          ];
        }
      ]).config.lmx.capabilities.editor.tools.example.args;
  };
  requiredPackage = {
    expected = "lmx.capabilities.editor.tools.example.package' was accessed but has no value defined";
    actual = missingPackage.config.lmx.capabilities.editor.tools.example.package.outPath;
  };
  requiredCommand = {
    expected = "lmx.capabilities.editor.tools.example.command' was accessed but has no value defined";
    actual = missingCommand.config.lmx.capabilities.editor.tools.example.command;
  };
  requiredParsers = {
    expected = "lmx.capabilities.editor.languages.example.parsers' was accessed but has no value defined";
    actual = missingParsers.config.lmx.capabilities.editor.languages.example.parsers;
  };
}
