{ pkgs, lib }:
let
  directory = ./fixtures/lines;
  evaluate = modules: { paths = map toString modules; };
  helper = import ./lines.nix {
    inherit pkgs lib;
    evalSystem = evaluate;
    moduleDirectory = directory;
    checkLine =
      { line, configuration }:
      configuration.config.paths == [ (toString (directory + "/versions/${line}.nix")) ]
      && configuration.pkgs.stdenv.hostPlatform.system == pkgs.stdenv.hostPlatform.system
      && configuration.lib.version == lib.version;
    runLine =
      { line, configuration }:
      pkgs.runCommand "shared-line-${line}" {
        selectedPath = builtins.head configuration.config.paths;
      } "touch $out";
  };
  lazyHelper = import ./lines.nix {
    inherit pkgs lib;
    evalSystem = _: throw "Metadata inspection evaluated a line";
    moduleDirectory = directory;
    checkLine = _: throw "Metadata inspection invoked checkLine";
  };
  wrong = import ./lines.nix {
    inherit pkgs lib;
    evalSystem = evaluate;
    moduleDirectory = directory;
    checkLine = _: "not a Boolean";
  };
in
{
  numericLines =
    helper.lines == [
      "1.9"
      "1.10"
    ];
  lineCallbacks =
    builtins.all (value: value == true) (builtins.attrValues helper.eval)
    &&
      builtins.attrNames helper.eval == [
        "line-1.10"
        "line-1.9"
      ];
  lineRuntimeRecipes =
    builtins.attrNames helper.run == [
      "commands-1.10"
      "commands-1.9"
    ]
    && builtins.all lib.isDerivation (builtins.attrValues helper.run);
  lazyLineFixtures =
    lazyHelper.lines == [
      "1.9"
      "1.10"
    ]
    && lazyHelper.run == { };
  separateLineFixtures =
    helper.defaultConfiguration.config.paths == [ (toString (directory + "/default.nix")) ]
    &&
      helper.allConfiguration.config.paths
      == map (line: toString (directory + "/versions/${line}.nix")) helper.lines;
  strictLinePredicate = !(builtins.tryEval wrong.eval."line-1.9").success;
}
