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
  commands = pkgs.runCommand "terraform-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${profile}/bin/terraform-${version})" = "$(readlink -f ${tools.terraform}/bin/terraform)"
    ${profile}/bin/terraform-${version} version | grep -F '${tools.terraform.version}'
    touch "$out"
  '';
}
// pkgs.lib.optionalAttrs includeShared {
  coexistence = import ../../checks/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    directory = ./.;
    commands = {
      terraform = "terraform";
    };
  };
}
