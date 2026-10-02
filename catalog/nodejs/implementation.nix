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
  rank = builtins.length olderReleases;
  priority = lib.meta.defaultPriority - rank;

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
  lmx.capabilities.languageSupport = {
    languages = {
      javascript.parsers = [ "javascript" ];
      typescript.parsers = [
        "typescript"
        "tsx"
      ];
    };
    tools.typescript-language-server = lib.mkOverride (1000 - rank) {
      package = lib.setPrio priority pkgs.typescript-language-server;
      command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
      args = [ "--stdio" ];
      languages = [
        "javascript"
        "typescript"
      ];
    };
  };

  environment.systemPackages = [
    (lib.setPrio priority tools.nodejs)
    versionedNode
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Node.js ${tools.nodejs.version} no longer receives upstream security updates.";
}
