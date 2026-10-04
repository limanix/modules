version:
{
  pkgs,
  lib,
  pinned,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version pinned;
  };

  catalog = import ./releases.nix;
  source = catalog.sources.${catalog.versions.${version}.source};
  releases = builtins.attrValues catalog.versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.nodejs.version
  ) releases;
  rank = builtins.length olderReleases;
  priority = lib.meta.defaultPriority - rank;

  versionedNode =
    pkgs.runCommandLocal "nodejs-${version}-commands"
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
  assertions = [
    {
      assertion = rank >= 0 && rank < 100;
      message = "nodejs: provider recommendation rank must be between 0 and 99";
    }
  ];

  lmx = {
    pins.${source.rev} = source.sha256;
    internal.nodejs.packages.${version} = tools;

    capabilities.languageSupport = {
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
  };

  environment.systemPackages = [
    (lib.setPrio priority tools.nodejs)
    versionedNode
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Node.js ${tools.nodejs.version} no longer receives upstream security updates.";
}
