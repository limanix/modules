{
  evalSystem,
  pkgs,
  lib,
}:
import ../../_shared/test/toolchain.nix {
  inherit evalSystem pkgs lib;
  spec = import ./toolchain.nix;
  coexisting = [
    "python"
    "virtualenv"
  ];
  profileCommands = tools: {
    python = "${tools.python}/bin/python";
    virtualenv = "${tools.virtualenv}/bin/virtualenv";
  };
  commands =
    {
      line,
      profile,
      tools,
      ...
    }:
    pkgs.runCommand "python-${line}-commands-smoke" { nativeBuildInputs = [ profile ]; } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      test "$(readlink -f ${profile}/bin/python-${line})" = "$(readlink -f ${tools.python.interpreter})"
      python-${line} -c 'import platform; assert platform.python_version() == "${tools.python.version}"'
      python-${line} -m venv environment
      environment/bin/python -m pip --version
      environment/bin/python -c 'import sys; assert sys.prefix != sys.base_prefix'
      ${tools.virtualenv}/bin/virtualenv --no-download virtual-environment
      virtual-environment/bin/python -m pip --version
      touch "$out"
    '';
  eval =
    {
      variants,
      configurations,
      allConfiguration,
      toolsFor,
      verify,
      installedAsDeclared,
      selectedPackage,
      packagePriority,
      ...
    }:
    let
      runtimeOutputSelection =
        variant:
        let
          configuration = configurations.${variant.version};
          tools = toolsFor variant.version;
          priority =
            lib.meta.defaultPriority
            - builtins.length (
              builtins.filter (other: lib.versionOlder other.version variant.version) variants
            );
          installed = lib.findFirst (
            package: toString package == tools.python.outPath
          ) null configuration.config.environment.systemPackages;
          profile = pkgs.buildEnv {
            name = "python-${variant.version}-runtime-output-selection";
            paths = [ installed ];
            extraOutputsToInstall = [
              "doc"
              "man"
              "info"
            ];
          };
          selected = map toString (lib.concatMap (entry: entry.paths) profile.chosenOutputs);
        in
        installed != null
        && installed.outPath == tools.python.outPath
        && installed.drvPath == tools.python.drvPath
        && installed.interpreter == tools.python.interpreter
        && installed.version == tools.python.version
        && builtins.elem tools.python.outPath selected
        && !(builtins.elem tools.python.doc.outPath selected)
        && selectedPackage configuration tools.python
        && packagePriority installed == priority
        && installedAsDeclared configuration (lib.setPrio priority tools.python);
    in
    {
      runtimeOutputSelection =
        verify "every interpreter retains runtime identity without implicit HTML docs"
          (builtins.all runtimeOutputSelection variants)
          allConfiguration;
    };
}
