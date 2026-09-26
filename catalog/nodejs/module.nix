version:
{ pkgs, lib, ... }:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  releases = builtins.attrValues (import ./releases.nix).versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.nodejs.version
  ) releases;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedNode =
    pkgs.runCommand "nodejs-${version}-commands"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p "$out/bin"
        ln -s "${tools.nodejs}/bin/node" "$out/bin/node-${version}"

        for command in npm npx; do
          makeWrapper "${tools.nodejs}/bin/$command" "$out/bin/$command-${version}" \
            --prefix PATH : "${tools.nodejs}/bin"
        done
      '';
in
{
  environment.systemPackages = [
    (lib.setPrio priority tools.nodejs)
    versionedNode
  ];

  warnings = lib.optional tools.endOfLife "Node.js ${tools.nodejs.version} no longer receives upstream security updates.";
}
