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
      node = "nodejs";
      npm = "nodejs";
      npx = "nodejs";
    };
  };
  commands =
    pkgs.runCommand "nodejs-${version}-commands-smoke"
      {
        nativeBuildInputs = [ config.system.path ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        test "$(readlink -f ${config.system.path}/bin/node-${version})" = "$(readlink -f ${tools.nodejs}/bin/node)"
        node-${version} -e 'if (process.version !== "v${tools.nodejs.version}") process.exit(1)'
        npm-${version} --version
        npx-${version} --version
        printf '{"name":"smoke","version":"1.0.0","scripts":{"check":"node check.js"}}' > package.json
        printf 'if(process.version!=="v${tools.nodejs.version}")process.exit(1);\n' > check.js
        npm-${version} run check --offline
        npx-${version} --offline -c 'node check.js'
        touch "$out"
      '';
}
