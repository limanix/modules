{
  profile,
  profileFor,
  pkgs,
  version,
  allVersionsConfiguration,
  includeShared,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
{
  commands =
    pkgs.runCommand "python-${version}-commands-smoke"
      {
        nativeBuildInputs = [ profile ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        test "$(readlink -f ${profile}/bin/python-${version})" = "$(readlink -f ${tools.python.interpreter})"
        python-${version} -c 'import platform; assert platform.python_version() == "${tools.python.version}"'
        python-${version} -m venv environment
        environment/bin/python -m pip --version
        environment/bin/python -c 'import sys; assert sys.prefix != sys.base_prefix'
        ${tools.virtualenv}/bin/virtualenv --no-download virtual-environment
        virtual-environment/bin/python -m pip --version
        touch "$out"
      '';
}
// pkgs.lib.optionalAttrs includeShared {
  coexistence = import ../../checks/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    directory = ./.;
    commands = {
      python = "python";
      virtualenv = "virtualenv";
    };
  };
}
