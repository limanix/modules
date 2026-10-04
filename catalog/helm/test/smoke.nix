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
  commands = pkgs.runCommand "helm-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${profile}/bin/helm-${version})" = "$(readlink -f ${tools.helm}/bin/helm)"
    ${profile}/bin/helm-${version} version --short | grep -F 'v${tools.helm.version}'
    ${profile}/bin/helm-${version} lint ${./fixtures/chart}
    ${profile}/bin/helm-${version} template module-test ${./fixtures/chart} --set message=module-ok > "$TMPDIR/rendered.yaml"
    grep -Fx '  name: module-test' "$TMPDIR/rendered.yaml"
    grep -Fx '  message: "module-ok"' "$TMPDIR/rendered.yaml"
    touch "$out"
  '';
}
// pkgs.lib.optionalAttrs includeShared {
  coexistence = import ../../_shared/test/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    expectedCommands = {
      helm = "${newestTools.helm}/bin/helm";
    };
  };
}
