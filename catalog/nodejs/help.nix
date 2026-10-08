{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.nodejs.versions);
  versions = map (line: config.lmx.internal.nodejs.packages.${line}.nodejs.version) selected;
  versioned = line: [
    "node-${line}"
    "npm-${line}"
    "npx-${line}"
  ];
in
{
  limanix.help.nodejs = {
    title = "Node.js ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [
      "node"
      "npm"
      "npx"
      "typescript-language-server"
    ]
    ++ lib.concatMap versioned selected;
    tips = [
      {
        label = "Install";
        text = "npm install";
      }
      {
        label = "Build";
        text = "npm run build";
      }
      {
        label = "node-gyp";
        text = "Add Python, make, and a C/C++ compiler for native addons.";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/nodejs/README.html";
  };
}
