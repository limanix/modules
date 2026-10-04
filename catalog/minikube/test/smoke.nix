{
  profile,
  profileFor,
  pkgs,
  version,
  tools,
  newestTools,
  allVersionsConfiguration,
  includeShared,
  ...
}:
{
  commands = pkgs.runCommand "minikube-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${profile}/bin/minikube-${version})" = "$(readlink -f ${tools.minikube}/bin/minikube)"
    ${profile}/bin/minikube-${version} version --short | grep -F '${tools.minikube.version}'
    touch "$out"
  '';
}
// pkgs.lib.optionalAttrs includeShared {
  coexistence = import ../../_shared/test/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    expectedCommands = {
      minikube = "${newestTools.minikube}/bin/minikube";
    };
  };
}
