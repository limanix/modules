# The tests every toolchain exports: each line installs its packages, offers its parsers and
# warns at end of life; explicit lines coexist and the newest one wins; a user-selected language
# server replaces the recommendation; the installed server answers the LSP handshake.
{
  evalSystem,
  pkgs,
  lib,
  spec,
  coexisting,
  profileCommands,
  commands,
  check ? (_: true),
  serverSetup ? "",
  eval ? (_: { }),
  builds ? (_: { }),
}:
let
  helpers = import ./helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers)
    evaluate
    profileFor
    verify
    installed
    installedAsDeclared
    selectedPackage
    packagePriority
    ;
  inherit (spec) name tool main;
  lineTests = import ./lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = spec.directory;
    checkLine = { line, configuration }: checkLine line configuration;
    runLine =
      { line, configuration }:
      commands {
        inherit line configuration;
        profile = profileFor configuration;
        tools = toolsFor line;
        provider = declared configuration;
      };
  };
  inherit (lineTests)
    metadata
    lines
    configurations
    allConfiguration
    ;
  variants = map (version: {
    inherit version;
    path = spec.directory + "/versions/${version}.nix";
  }) lines;
  toolsFor = line: configurations.${line}.config.lmx.internal.${name}.packages.${line};
  capability = configuration: configuration.config.lmx.capabilities.languageSupport;
  declared = configuration: (capability configuration).tools.${tool};
  newest = toolsFor (lib.last lines);
  offer = spec.provider {
    tools = newest;
    inherit pkgs;
  };
  server = baseNameOf offer.command;

  checkLine =
    line: configuration:
    let
      tools = toolsFor line;
      warning = "${spec.title} ${tools.${main}.version} no longer receives upstream security updates.";
      offered = builtins.all (
        language:
        builtins.all (
          parser: builtins.elem parser (capability configuration).languages.${language}.parsers
        ) spec.parsers.${language}
      ) (builtins.attrNames spec.parsers);
    in
    builtins.all (installed configuration) [
      tools.${main}
      (declared configuration).package
    ]
    && offered
    && (builtins.elem warning configuration.config.warnings == (tools.endOfLife == true))
    && check {
      inherit line configuration tools;
      installed = installed configuration;
    };

  replacement = pkgs.writeShellScriptBin server ''
    test "$#" -ge 1 && test "$1" = --catalog-smoke || exit 64
    shift
    exec ${offer.package}/bin/${server} "$@"
  '';
  override = evaluate (
    map (variant: variant.path) variants
    ++ [
      {
        lmx.capabilities.languageSupport.tools.${tool} = {
          package = replacement;
          command = "${replacement}/bin/${server}";
          args = [ "--catalog-smoke" ] ++ (offer.args or [ ]);
        };
      }
    ]
  );

  serverSmoke =
    label: configuration:
    let
      record = declared configuration;
      profile = profileFor configuration;
    in
    pkgs.runCommand label { } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      ${serverSetup}
      test "$(readlink -f ${profile}/bin/${server})" = "$(readlink -f ${record.command})"
      timeout 30 ${pkgs.python3}/bin/python ${./lsp-smoke.py} \
        ${profile}/bin/${server} ${lib.escapeShellArgs (record.args or [ ])}
      touch "$out"
    '';

  context = {
    inherit
      lines
      variants
      configurations
      allConfiguration
      toolsFor
      evaluate
      verify
      installedAsDeclared
      selectedPackage
      packagePriority
      lib
      pkgs
      ;
  };
  recommendation = declared allConfiguration;
in
{
  eval =
    lineTests.eval
    // {
      allLines =
        verify "${name}: explicit lines coexist and the newest line's provider is declared and installed"
          (
            builtins.all (variant: checkLine variant.version allConfiguration) variants
            && builtins.all (attribute: selectedPackage allConfiguration newest.${attribute}) coexisting
            && recommendation.package.outPath == offer.package.outPath
            &&
              packagePriority recommendation.package
              == lib.meta.defaultPriority - (spec.priorityOffset or 0) - (builtins.length lines - 1)
            && installedAsDeclared allConfiguration recommendation.package
            && recommendation.command == offer.command
            && (recommendation.args or [ ]) == (offer.args or [ ])
            && recommendation.languages == offer.languages
            && selectedPackage allConfiguration offer.package
          )
          allConfiguration;
      userOverride =
        verify "${name}: a user-selected provider replaces the recommendation in the system profile"
          (selectedPackage override replacement && installedAsDeclared override replacement)
          override;
    }
    // eval context;
  run = lineTests.run // {
    languageServer = serverSmoke "${name}-declared-language-server" configurations.${metadata.default};
    userOverride = serverSmoke "${name}-user-selected-provider" override;
    allLines = import ./profile-commands.nix {
      inherit pkgs;
      profile = profileFor allConfiguration;
      expectedCommands = profileCommands newest;
    };
  };
  builds = builds context;
}
