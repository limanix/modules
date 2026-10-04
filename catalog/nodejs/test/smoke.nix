{
  config,
  profile,
  profileFor,
  pkgs,
  version,
  tools,
  expectedTools,
  allConfiguration,
  includeShared,
  configurations,
  ...
}:
let
  serverSmoke =
    name: configuration:
    let
      tool = configuration.config.lmx.capabilities.languageSupport.tools.typescript-language-server;
      serverProfile = profileFor configuration;
    in
    pkgs.runCommand name { } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      test "$(readlink -f ${serverProfile}/bin/typescript-language-server)" = "$(readlink -f ${tool.command})"
      timeout 30 ${pkgs.python3}/bin/python ${../../_shared/test/lsp-smoke.py} \
        ${serverProfile}/bin/typescript-language-server ${pkgs.lib.escapeShellArgs tool.args}
      touch "$out"
    '';
in
{
  commands =
    pkgs.runCommand "nodejs-${version}-commands-smoke"
      {
        nativeBuildInputs = [ profile ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        test "$(readlink -f ${profile}/bin/node-${version})" = "$(readlink -f ${tools.nodejs}/bin/node)"
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
// pkgs.lib.optionalAttrs includeShared {
  languageServer = serverSmoke "nodejs-declared-language-server" { inherit config; };
  userOverride = serverSmoke "nodejs-user-selected-provider" configurations.userOverride;
  allLines = import ../../_shared/test/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allConfiguration;
    expectedCommands = {
      node = "${expectedTools.nodejs}/bin/node";
      npm = "${expectedTools.nodejs}/bin/npm";
      npx = "${expectedTools.nodejs}/bin/npx";
    };
  };
}
