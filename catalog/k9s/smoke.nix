{
  profile,
  profileFor,
  pkgs,
  version,
  selector,
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
  commands = pkgs.runCommand "k9s-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${profile}/bin/k9s)" = "$(readlink -f ${tools.k9s}/bin/k9s)"
    ${profile}/bin/k9s version | grep -F '${tools.k9s.version}'
    ${pkgs.lib.optionalString (selector != "k9s") ''
      test "$(readlink -f ${profile}/bin/k9s-${version})" = "$(readlink -f ${tools.k9s}/bin/k9s)"
      ${profile}/bin/k9s-${version} version | grep -F '${tools.k9s.version}'
    ''}
    touch "$out"
  '';
}
// pkgs.lib.optionalAttrs (version == "0.40") {
  upstreamVersion = tools.k9s.tests.version;
}
// pkgs.lib.optionalAttrs includeShared {
  coexistence = import ../../checks/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    directory = ./.;
    commands = {
      k9s = "k9s";
    };
  };
}
