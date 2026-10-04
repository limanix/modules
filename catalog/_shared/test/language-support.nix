{ lib, pkgs }:
let
  schema =
    modules:
    (lib.evalModules {
      modules = [ ../languageSupport.nix ] ++ modules;
    }).config.lmx.capabilities.languageSupport;
  required = {
    package = pkgs.hello;
    command = "${pkgs.hello}/bin/hello";
  };
  complete = required // {
    args = [ "--example" ];
    languages = [ "example" ];
  };
  empty = schema [ ];
  normalized = schema [
    { lmx.capabilities.languageSupport.tools.example = required; }
    {
      lmx.capabilities.languageSupport.tools.example = required // {
        args = [ ];
        languages = [ ];
      };
    }
  ];
  equal = schema [
    { lmx.capabilities.languageSupport.tools.example = complete; }
    { lmx.capabilities.languageSupport.tools.example = complete; }
  ];
  atomic = schema [
    { lmx.capabilities.languageSupport.tools.example = lib.mkOverride 1000 complete; }
    {
      lmx.capabilities.languageSupport.tools.example = lib.mkOverride 999 {
        package = pkgs.coreutils;
        command = "${pkgs.coreutils}/bin/true";
      };
    }
  ];
  parsers = schema [
    {
      lmx.capabilities.languageSupport.languages.example.parsers = [
        "first"
        "shared"
      ];
    }
    {
      lmx.capabilities.languageSupport.languages.example.parsers = [
        "shared"
        "second"
      ];
    }
  ];
  # Force only the selected ABI value; derivation attrs may contain cycles.
  forceToolField = field: { config, ... }: {
    assertions = [
      {
        assertion = builtins.deepSeq (
          if field == "package" then
            config.lmx.capabilities.languageSupport.tools.example.package.outPath
          else
            config.lmx.capabilities.languageSupport.tools.example.${field}
        ) true;
        message = "Shared tests: force language tool ${field}";
      }
    ];
  };
  conflict = field: first: second: {
    modules = [
      { lmx.capabilities.languageSupport.tools.example = first; }
      { lmx.capabilities.languageSupport.tools.example = second; }
      (forceToolField field)
    ];
    message = "lmx.capabilities.languageSupport.tools.example' has conflicting definition values";
  };
in
{
  eval = {
    emptyCapabilities = empty.tools == { } && empty.languages == { };
    normalizedDeclarations =
      normalized.tools.example == required
      // {
        args = [ ];
        languages = [ ];
      };
    equalDeclarations = equal.tools.example == complete;
    atomicDeclaration =
      atomic.tools.example.package.outPath == pkgs.coreutils.outPath
      && atomic.tools.example.command == "${pkgs.coreutils}/bin/true"
      && atomic.tools.example.args == [ ]
      && atomic.tools.example.languages == [ ];
    parserContributions =
      parsers.tools == { }
      &&
        builtins.sort builtins.lessThan parsers.languages.example.parsers == [
          "first"
          "second"
          "shared"
        ];
  };
  fails = {
    conflictingCommands = conflict "command" required (required // { command = "different"; });
    conflictingArgs = conflict "args" required (required // { args = [ "different" ]; });
    conflictingLanguages = conflict "languages" required (required // { languages = [ "different" ]; });
    missingToolCommand = {
      modules = [
        { lmx.capabilities.languageSupport.tools.example.package = pkgs.hello; }
        (forceToolField "command")
      ];
      message = "lmx.capabilities.languageSupport.tools.example.command' was accessed but has no value defined";
    };
    missingToolPackage = {
      modules = [
        { lmx.capabilities.languageSupport.tools.example.command = "example"; }
        (forceToolField "package")
      ];
      message = "lmx.capabilities.languageSupport.tools.example.package' was accessed but has no value defined";
    };
    missingParserList = {
      modules = [
        { lmx.capabilities.languageSupport.languages.example = { }; }
        ({ config, ... }: {
          assertions = [
            {
              assertion = builtins.deepSeq config.lmx.capabilities.languageSupport.languages.example.parsers true;
              message = "Shared tests: force parser requirements";
            }
          ];
        })
      ];
      message = "lmx.capabilities.languageSupport.languages.example.parsers' was accessed but has no value defined";
    };
  };
}
