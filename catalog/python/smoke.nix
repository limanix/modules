{
  config,
  profile,
  profileFor,
  pkgs,
  version,
  allVersionsConfiguration,
  includeShared,
  configurations,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  serverSmoke =
    name: configuration:
    let
      tool = configuration.config.lmx.capabilities.languageSupport.tools.pyright;
      serverProfile = profileFor configuration;
    in
    pkgs.runCommand name { } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      test "$(readlink -f ${serverProfile}/bin/pyright-langserver)" = "$(readlink -f ${tool.command})"
      timeout 30 ${pkgs.python3}/bin/python ${../../checks/lsp-smoke.py} \
        ${serverProfile}/bin/pyright-langserver ${pkgs.lib.escapeShellArgs tool.args}
      touch "$out"
    '';
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
  languageServer = serverSmoke "python-declared-language-server" { inherit config; };
  providerOverride = serverSmoke "python-user-selected-provider" configurations.providerOverride;
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
