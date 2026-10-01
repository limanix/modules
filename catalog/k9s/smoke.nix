{
  config,
  pkgs,
  version,
  selector,
  evaluateStandalone,
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
    inherit pkgs evaluateStandalone;
    directory = ./.;
    commands = {
      k9s = "k9s";
    };
  };
  commands = pkgs.runCommand "k9s-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${config.system.path}/bin/k9s)" = "$(readlink -f ${tools.k9s}/bin/k9s)"
    ${config.system.path}/bin/k9s version | grep -F '${tools.k9s.version}'
    ${pkgs.lib.optionalString (selector != "k9s") ''
      test "$(readlink -f ${config.system.path}/bin/k9s-${version})" = "$(readlink -f ${tools.k9s}/bin/k9s)"
      ${config.system.path}/bin/k9s-${version} version | grep -F '${tools.k9s.version}'
    ''}
    touch "$out"
  '';
}
