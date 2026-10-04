{
  profile,
  profileFor,
  pkgs,
  version,
  allVersionsConfiguration,
  includeShared,
  tools,
  expectedTools,
  ...
}:
{
  commands = pkgs.runCommand "k9s-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${profile}/bin/k9s)" = "$(readlink -f ${tools.k9s}/bin/k9s)"
    ${profile}/bin/k9s version | grep -F '${tools.k9s.version}'
    test "$(readlink -f ${profile}/bin/k9s-${version})" = "$(readlink -f ${tools.k9s}/bin/k9s)"
    ${profile}/bin/k9s-${version} version | grep -F '${tools.k9s.version}'
    touch "$out"
  '';
}
// pkgs.lib.optionalAttrs includeShared {
  coexistence = import ../../_shared/test/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    expectedCommands.k9s = "${expectedTools.k9s}/bin/k9s";
  };
}
