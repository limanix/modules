{
  evalSystem,
  pkgs,
  lib,
}:
import ../../_shared/test/toolchain.nix {
  inherit evalSystem pkgs lib;
  spec = import ./toolchain.nix;
  coexisting = [
    "runtime"
    "virtualenv"
  ];
  profileCommands = tools: {
    python = "${tools.runtime}/bin/python";
    virtualenv = "${tools.virtualenv}/bin/virtualenv";
  };
  commands =
    {
      line,
      profile,
      tools,
      ...
    }:
    pkgs.runCommandCC "python-${line}-commands-smoke" { nativeBuildInputs = [ profile ]; } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      test "$(readlink -f ${profile}/bin/python-${line})" = "$(readlink -f ${tools.runtime}/bin/python${tools.python.pythonVersion})"
      python-${line} -c 'import platform; assert platform.python_version() == "${tools.python.version}"'
      printf '#include <string>\nextern "C" int answer() { return std::string("forty-two").size() + 33; }\n' > wheel.cpp
      NIX_DONT_SET_RPATH=1 g++ -shared -fPIC -o libwheel.so wheel.cpp
      load='import ctypes; assert ctypes.CDLL("./libwheel.so").answer() == 42'
      ! ${tools.python.interpreter} -c "$load" 2> /dev/null
      python-${line} -c "$load"
      python-${line} -c 'import os; assert "LD_LIBRARY_PATH" not in os.environ'
      python-${line} -m venv environment
      environment/bin/python -m pip --version
      environment/bin/python -c 'import sys; assert sys.prefix != sys.base_prefix'
      environment/bin/python -c "$load"
      ${tools.virtualenv}/bin/virtualenv --no-download virtual-environment
      virtual-environment/bin/python -m pip --version
      virtual-environment/bin/python -c 'import platform; assert platform.python_version() == "${tools.python.version}"'
      virtual-environment/bin/python -c "$load"
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
      ...
    }:
    let
      runtimeSelection =
        variant:
        let
          configuration = configurations.${variant.version};
          tools = toolsFor variant.version;
          priority =
            lib.meta.defaultPriority
            - builtins.length (
              builtins.filter (other: lib.versionOlder other.version variant.version) variants
            );
          raw = builtins.any (
            package: toString package == tools.python.outPath
          ) configuration.config.environment.systemPackages;
        in
        tools.runtime.outputs == [ "out" ]
        && selectedPackage configuration tools.runtime
        && installedAsDeclared configuration (lib.setPrio priority tools.runtime)
        && !raw;
    in
    {
      runtimeSelection =
        verify "every line installs its wrapped interpreter in place of the raw one, without HTML docs"
          (builtins.all runtimeSelection variants)
          allConfiguration;
    };
}
