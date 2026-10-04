{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) profileFor installed;
  toolsFor = configuration: line: configuration.config.lmx.internal.docker.packages.${line};
  lineTests = import ../_shared/test/lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = ./.;
    checkLine =
      { line, configuration }:
      import ./test/check.nix {
        inherit (configuration) config;
        inherit pkgs;
        tools = toolsFor configuration line;
        userName = configuration.config.limanix.user.name;
        hasPackage = installed configuration;
      };
    runLine =
      { line, configuration }:
      (import ./test/smoke.nix {
        inherit pkgs;
        profile = profileFor configuration;
        version = line;
      }).commands;
  };
in
{
  inherit (lineTests) eval run;
  fails.twoLines = {
    modules = map (line: ./versions + "/${line}.nix") lineTests.lines;
    message = "docker: select one line";
  };
  vm.activation = import ./test/vm.nix { inherit pkgs; };
}
