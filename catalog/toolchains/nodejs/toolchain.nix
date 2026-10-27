{
  name = "nodejs";
  title = "Node.js";
  directory = ./.;
  main = "nodejs";
  tool = "typescript-language-server";
  parsers = {
    javascript = [ "javascript" ];
    typescript = [
      "typescript"
      "tsx"
    ];
  };
  packages = import ./packages.nix;
  provider =
    { pkgs, ... }:
    {
      package = pkgs.typescript-language-server;
      command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
      args = [ "--stdio" ];
      languages = [
        "javascript"
        "typescript"
      ];
    };
  systemPackages =
    {
      version,
      tools,
      pkgs,
      lib,
      priority,
    }:
    [
      (lib.setPrio priority tools.nodejs)
      (pkgs.runCommandLocal "nodejs-${version}-commands" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
        mkdir -p "$out/bin"
        ln -s "${tools.nodejs}/bin/node" "$out/bin/node-${version}"

        for command in npm npx; do
          makeWrapper "${tools.nodejs}/bin/$command" "$out/bin/$command-${version}" \
            --prefix PATH : "${tools.nodejs}/bin"
        done
      '')
    ];
  commands = [
    "node"
    "npm"
    "npx"
    "typescript-language-server"
  ];
  versioned = line: [
    "node-${line}"
    "npm-${line}"
    "npx-${line}"
  ];
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
      text = "Select gcc and python in [toolchains] for native addons.";
    }
  ];
  page = "modules/nodejs";
}
