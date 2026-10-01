{
  config,
  pkgs,
  version,
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
      terraform = "terraform";
    };
  };
  commands = pkgs.runCommand "terraform-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${config.system.path}/bin/terraform-${version})" = "$(readlink -f ${tools.terraform}/bin/terraform)"
    ${config.system.path}/bin/terraform-${version} version | grep -F '${tools.terraform.version}'
    touch "$out"
  '';
}
