{
  evalSystem,
  pkgs,
  lib,
}:
import ../../_shared/test/toolchain.nix {
  inherit evalSystem pkgs lib;
  spec = import ./toolchain.nix;
  coexisting = [ "nodejs" ];
  profileCommands = tools: {
    node = "${tools.nodejs}/bin/node";
    npm = "${tools.nodejs}/bin/npm";
    npx = "${tools.nodejs}/bin/npx";
  };
  commands =
    {
      line,
      profile,
      tools,
      ...
    }:
    pkgs.runCommand "nodejs-${line}-commands-smoke" { nativeBuildInputs = [ profile ]; } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      test "$(readlink -f ${profile}/bin/node-${line})" = "$(readlink -f ${tools.nodejs}/bin/node)"
      node-${line} -e 'if (process.version !== "v${tools.nodejs.version}") process.exit(1)'
      npm-${line} --version
      npx-${line} --version
      printf '{"name":"smoke","version":"1.0.0","scripts":{"check":"node check.js"}}' > package.json
      printf 'if(process.version!=="v${tools.nodejs.version}")process.exit(1);\n' > check.js
      npm-${line} run check --offline
      npx-${line} --offline -c 'node check.js'
      touch "$out"
    '';
  builds =
    { lines, toolsFor, ... }:
    builtins.listToAttrs (
      lib.concatMap (
        line:
        lib.optional ((toolsFor line) ? npm) {
          name = "npm-${line}";
          value = (toolsFor line).npm;
        }
      ) lines
    );
}
