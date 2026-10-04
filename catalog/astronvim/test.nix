{
  evalSystem,
  pkgs,
  lib,
}:
let
  inherit (import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; })
    evaluate
    verify
    installed
    installedAsDeclared
    ;
  lineTests = import ../_shared/test/lines.nix {
    inherit evalSystem pkgs lib;
    moduleDirectory = ./.;
    checkLine =
      { configuration, ... }:
      import ./test/check.nix {
        inherit (configuration) config;
        hasPackage = installed configuration;
      };
    runLine =
      { configuration, ... }:
      (import ./test/smoke.nix {
        inherit pkgs;
        inherit (configuration) config;
      }).commands;
  };
  inherit (lineTests) metadata lines;
  defaults = lineTests.configurations.${metadata.default};
  entry = ./versions + "/${metadata.default}.nix";
  preferences = evaluate [
    entry
    {
      programs.neovim.defaultEditor = false;
      programs.nix-ld.enable = false;
    }
  ];
  catalog = evaluate [
    entry
    ../rust/default.nix
  ];
  suppliedGopls = pkgs.writeShellScriptBin "gopls" ''
    test "$#" -ge 1 && test "$1" = --catalog-smoke || exit 64
    shift
    exec ${pkgs.gopls}/bin/gopls "$@"
  '';
  suppliedTool = {
    package = suppliedGopls;
    command = "${suppliedGopls}/bin/gopls";
    args = [ "--catalog-smoke" ];
    languages = [ "go" ];
  };
  thirdParty = evaluate [
    entry
    {
      environment.systemPackages = [
        pkgs.go
        suppliedGopls
      ];
      lmx.capabilities.languageSupport = {
        tools.gopls = suppliedTool;
        languages.go.parsers = [ "go" ];
      };
    }
  ];
  capability = configuration: configuration.config.lmx.capabilities.languageSupport;
  serverName = import ./server-name.nix;
  ownedPackages =
    configuration:
    import ./packages.nix {
      inherit pkgs lib;
      version = builtins.head configuration.config.lmx.internal.astronvim.versions;
      parsers = lib.unique (
        lib.concatMap (language: language.parsers) (
          builtins.attrValues (capability configuration).languages
        )
      );
    };
  basePackages = ownedPackages defaults;
  catalogPackages = ownedPackages catalog;
  thirdPartyPackages = ownedPackages thirdParty;
  # Optional plugin integrations are explicit checkInputs in Nixpkgs. Stdenv
  # removes those fields from the resulting derivation; retain metadata only.
  applicationCheckPlugins =
    plugin:
    let
      annotated = plugin.overrideAttrs (previous: {
        passthru = (previous.passthru or { }) // {
          lmxCheckPlugins = (previous.checkInputs or [ ]) ++ (previous.nativeCheckInputs or [ ]);
        };
      });
    in
    assert lib.assertMsg (
      annotated.drvPath == plugin.drvPath
    ) "AstroNvim: check plugin metadata must preserve the original derivation";
    builtins.filter (
      input: lib.isDerivation input && (input.vimPlugin or false)
    ) annotated.lmxCheckPlugins;
  # Follow application declarations only, never generic derivation inputs.
  withPluginDependencies =
    plugin:
    [ plugin ]
    ++ lib.concatMap withPluginDependencies (
      (plugin.dependencies or [ ]) ++ applicationCheckPlugins plugin
    );
  pluginPackages = lib.concatMap withPluginDependencies (
    lib.concatMap (packages: builtins.attrValues packages.plugins) [
      basePackages
      catalogPackages
      thirdPartyPackages
    ]
    ++ [ pkgs.vimPlugins.catppuccin-nvim ]
    ++ lib.optional (!(basePackages.plugins ? "folke/lazy.nvim")) pkgs.vimPlugins.lazy-nvim
  );
  pluginBuilds = builtins.listToAttrs (
    map (plugin: {
      # Package names can contain characters outside the public export grammar.
      name = "plugin${builtins.hashString "sha256" (builtins.unsafeDiscardStringContext plugin.drvPath)}-${metadata.default}";
      value = plugin;
    }) pluginPackages
  );
  features = builtins.removeAttrs (import ./test/smoke.nix {
    inherit pkgs;
    inherit (defaults) config;
  }) [ "commands" ];
in
{
  eval = lineTests.eval // {
    preferences = verify "editor and compatibility-loader preferences accept ordinary settings" (
      !preferences.config.programs.neovim.defaultEditor
      && !preferences.config.programs.nix-ld.enable
      && preferences.config.programs.neovim.enable
    ) preferences;
    optionalProviders = verify "language providers remain optional" (
      (capability defaults).tools == { }
      && (capability defaults).languages == { }
      && !installed defaults (capability catalog).tools.rust-analyzer.package
    ) defaults;
    catalogProvider = verify "a catalog declaration supplies the editor's selected tool and parser" (
      catalog.config.programs.neovim.enable
      && installedAsDeclared catalog (capability catalog).tools.rust-analyzer.package
      && builtins.elem "rust" (capability catalog).languages.rust.parsers
    ) catalog;
    thirdPartyProvider = verify "the editor accepts a supplied executable and its arguments" (
      thirdParty.config.programs.neovim.enable
      && (capability thirdParty).tools.gopls.command == suppliedTool.command
      && (capability thirdParty).tools.gopls.args == suppliedTool.args
      && installedAsDeclared thirdParty suppliedGopls
      && (capability thirdParty).languages.go.parsers == [ "go" ]
    ) thirdParty;
    serverNames = verify "consumer server names preserve both translations and the identity fallback" (
      serverName "rust-analyzer" == "rust_analyzer"
      && serverName "typescript-language-server" == "ts_ls"
      && serverName "gopls" == "gopls"
      && serverName "custom-server" == "custom-server"
    ) defaults;
  };
  fails = lib.optionalAttrs (builtins.length lines >= 2) {
    twoLines = {
      modules = map (line: ./versions + "/${line}.nix") (lib.take 2 lines);
      message = "astronvim: select one line";
    };
  };
  run =
    lineTests.run
    // features
    // {
      languageServer = import ./test/integration.nix {
        inherit pkgs;
        inherit (defaults) config;
        configurations = { inherit catalog thirdParty; };
      };
    };
  builds = {
    "astro-${metadata.default}" = basePackages.astro;
    "parsers-${metadata.default}" = basePackages.treesitter;
    "catalogParsers-${metadata.default}" = catalogPackages.treesitter;
    "thirdPartyParsers-${metadata.default}" = thirdPartyPackages.treesitter;
    "editor-${metadata.default}" = defaults.config.programs.neovim.finalPackage;
    "catalogEditor-${metadata.default}" = catalog.config.programs.neovim.finalPackage;
    "thirdPartyEditor-${metadata.default}" = thirdParty.config.programs.neovim.finalPackage;
  }
  // pluginBuilds;
}
