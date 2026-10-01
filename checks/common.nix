let
  system = builtins.currentSystem;
  nixpkgs = import ./nixpkgs.nix;
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;
  catalog = import ./catalog.nix ../catalog;
  shared = import ./shared-files.nix;
  schemaFor =
    modules:
    lib.evalModules {
      specialArgs = { inherit pkgs; };
      modules = [ ../interface.nix ] ++ shared.public ++ modules;
    };
  empty = schemaFor [ ];
  capability = configuration: configuration.config.lmx.capabilities.languageSupport;
  verify =
    label: valid:
    builtins.trace "Checking ${system}: common: ${label}" (
      if valid then true else throw "Common contract: ${label}"
    );
  declaration = {
    package = pkgs.hello;
    command = "${pkgs.hello}/bin/hello";
    args = [
      "--greeting"
      "hello"
    ];
    languages = [ "example" ];
  };
  required = {
    package = pkgs.hello;
    command = "${pkgs.hello}/bin/hello";
  };
  equalDeclarations = schemaFor [
    { lmx.capabilities.languageSupport.tools.example = lib.mkDefault declaration; }
    { lmx.capabilities.languageSupport.tools.example = lib.mkDefault declaration; }
  ];
  equalDefaults = schemaFor [
    { lmx.capabilities.languageSupport.tools.example = lib.mkDefault required; }
    {
      lmx.capabilities.languageSupport.tools.example = lib.mkDefault (
        required
        // {
          args = [ ];
          languages = [ ];
        }
      );
    }
  ];
  weak = {
    lmx.capabilities.languageSupport.tools.example = lib.mkOverride 1000 (
      required
      // {
        args = [ "discarded" ];
        languages = [ "discarded" ];
      }
    );
  };
  conflictingWeak = {
    lmx.capabilities.languageSupport.tools.example = lib.mkOverride 1000 (
      required
      // {
        args = [ "also-discarded" ];
      }
    );
  };
  strong = {
    lmx.capabilities.languageSupport.tools.example = lib.mkOverride 999 {
      package = pkgs.coreutils;
      command = "${pkgs.coreutils}/bin/true";
    };
  };
  prioritySelected = schemaFor [
    weak
    conflictingWeak
    strong
  ];
  priorityReversed = schemaFor [
    strong
    conflictingWeak
    weak
  ];
  selected = (capability prioritySelected).tools.example;
  parsers = schemaFor [
    { lmx.capabilities.languageSupport.languages.go.parsers = [ "go" ]; }
    {
      lmx.capabilities.languageSupport.languages = {
        go.parsers = [ "gomod" ];
        python.parsers = [ "python" ];
      };
    }
  ];
  parserOnly = schemaFor [
    { lmx.capabilities.languageSupport.languages.example.parsers = [ "lua" ]; }
  ];
  identity = schemaFor [
    {
      limanix.user = {
        name = "module-check";
        home = "/home/module-check";
      };
    }
  ];
  rejectsIdentity =
    name:
    let
      original = identity.config.limanix.user.${name};
      repeated = schemaFor [
        {
          limanix.user = {
            name = "module-check";
            home = "/home/module-check";
          };
        }
        { limanix.user.${name} = original; }
      ];
    in
    builtins.deepSeq original (!(builtins.tryEval repeated.config.limanix.user.${name}).success);
  conflictingToolFields =
    values:
    schemaFor (
      map (fields: {
        lmx.capabilities.languageSupport.tools.example = lib.mkOverride 1000 (required // fields);
      }) values
    );
  conflictingTools = schemaFor [
    { lmx.capabilities.languageSupport.tools.example = lib.mkOverride 1000 required; }
    {
      lmx.capabilities.languageSupport.tools.example = lib.mkOverride 1000 {
        package = pkgs.coreutils;
        command = "${pkgs.coreutils}/bin/true";
      };
    }
  ];
  missingPackage = schemaFor [
    { lmx.capabilities.languageSupport.tools.example.command = "/example"; }
  ];
  missingCommand = schemaFor [
    { lmx.capabilities.languageSupport.tools.example.package = pkgs.hello; }
  ];
  missingParsers = schemaFor [ { lmx.capabilities.languageSupport.languages.example = { }; } ];
  evaluation = {
    catalog = builtins.deepSeq catalog true;
    nixpkgsPin = builtins.seq nixpkgs true;
    shared = import ./shared.nix { inherit nixpkgs system; };
    sharedDeclarations = import ./shared-tests.nix { inherit nixpkgs system; };
    ownership = import ./ownership-tests.nix { inherit nixpkgs system; };
    smokeRequirements = import ./smoke-requirements-tests.nix;
    componentDiscovery = import ./component-imports-tests.nix { inherit lib; };
    emptyCapabilities = verify "public capabilities exist without application modules" (
      (capability empty).tools == { } && (capability empty).languages == { }
    );
    parserOnly = verify "parser-only language needs no tool declaration" (
      (capability parserOnly).tools == { }
      && (capability parserOnly).languages.example.parsers == [ "lua" ]
    );
    languageContributions = verify "language contributions merge without dropping parsers" (
      builtins.sort builtins.lessThan (capability parsers).languages.go.parsers == [
        "go"
        "gomod"
      ]
      && (capability parsers).languages.python.parsers == [ "python" ]
      && (capability parsers).tools == { }
    );
    equalToolDeclarations = verify "identical complete declarations do not duplicate lists" (
      (capability equalDeclarations).tools.example == declaration
    );
    equalToolDefaults = verify "omitted and explicit optional defaults are equal" (
      (capability equalDefaults).tools.example == required
      // {
        args = [ ];
        languages = [ ];
      }
    );
    completeDeclaration = verify "precedence selects a complete declaration before fields merge" (
      selected.package.outPath == pkgs.coreutils.outPath
      && selected.command == "${pkgs.coreutils}/bin/true"
      && selected.args == [ ]
      && selected.languages == [ ]
      && builtins.toJSON selected == builtins.toJSON (capability priorityReversed).tools.example
    );
    readOnlyIdentity = verify "user name and home reject another definition" (
      builtins.all rejectsIdentity [
        "name"
        "home"
      ]
    );
  };
in
assert
  builtins.elem system [
    "aarch64-linux"
    "x86_64-linux"
  ]
  || throw "Common checks require a native Linux runner";
{
  inherit system evaluation;
  all = builtins.deepSeq evaluation true;
  diagnostics = {
    requiredSmoke = {
      expected = "example: custom builds or program configuration require smoke.nix";
      actual = builtins.deepSeq (import ./catalog.nix ./fixtures/smoke-required) true;
    };
    equalToolPrecedence = {
      expected = "lmx.capabilities.languageSupport.tools.example' has conflicting definition values";
      actual = (capability conflictingTools).tools.example.command;
    };
    equalToolPrecedenceArgs = {
      expected = "lmx.capabilities.languageSupport.tools.example' has conflicting definition values";
      actual =
        (capability (conflictingToolFields [
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
        ])).tools.example.args;
    };
    equalToolPrecedenceLanguages = {
      expected = "lmx.capabilities.languageSupport.tools.example' has conflicting definition values";
      actual =
        (capability (conflictingToolFields [
          { languages = [ "go" ]; }
          { languages = [ "rust" ]; }
        ])).tools.example.languages;
    };
    equalToolPrecedenceDefaultArgs = {
      expected = "lmx.capabilities.languageSupport.tools.example' has conflicting definition values";
      actual =
        (capability (conflictingToolFields [
          { }
          {
            args = [
              "--mode"
              "a"
            ];
          }
        ])).tools.example.args;
    };
    requiredPackage = {
      expected = "lmx.capabilities.languageSupport.tools.example.package' was accessed but has no value defined";
      actual = (capability missingPackage).tools.example.package.outPath;
    };
    requiredCommand = {
      expected = "lmx.capabilities.languageSupport.tools.example.command' was accessed but has no value defined";
      actual = (capability missingCommand).tools.example.command;
    };
    requiredParsers = {
      expected = "lmx.capabilities.languageSupport.languages.example.parsers' was accessed but has no value defined";
      actual = (capability missingParsers).languages.example.parsers;
    };
  };
}
