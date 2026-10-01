{ version }:
{ pkgs, ... }:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  versionedK9s = pkgs.runCommand "k9s-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.k9s}/bin/k9s" "$out/bin/k9s-${version}"
  '';
in
{
  imports = [ ./selection.nix ];

  lmx.internal.k9s.versions = [ version ];
  environment.systemPackages = [ versionedK9s ];
}
