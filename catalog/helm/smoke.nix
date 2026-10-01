{
  config,
  pkgs,
  version,
  evaluate,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
{
  coexistence = import ../../checks/profile-commands.nix {
    inherit pkgs evaluate;
    directory = ./.;
    commands = {
      helm = "helm";
    };
  };
  commands = pkgs.runCommand "helm-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${config.system.path}/bin/helm-${version})" = "$(readlink -f ${tools.helm}/bin/helm)"
    ${config.system.path}/bin/helm-${version} version --short | grep -F 'v${tools.helm.version}'
    touch "$out"
  '';
}
