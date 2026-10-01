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
      minikube = "minikube";
    };
  };
  commands = pkgs.runCommand "minikube-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${config.system.path}/bin/minikube-${version})" = "$(readlink -f ${tools.minikube}/bin/minikube)"
    ${config.system.path}/bin/minikube-${version} version --short | grep -F '${tools.minikube.version}'
    touch "$out"
  '';
}
