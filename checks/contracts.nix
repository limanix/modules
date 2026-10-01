{
  catalog,
  nixpkgs,
  system,
  userName,
}:
let
  configurationFor =
    modules:
    import ./nixos.nix {
      inherit
        nixpkgs
        system
        userName
        modules
        ;
    };
  empty = configurationFor [ ];
  inherit (empty) lib pkgs;
  entry = name: builtins.head (builtins.filter (module: module.name == name) catalog);
  path = name: (entry name).path;
  toolsFor =
    name: version:
    import (../catalog + "/${name}/packages.nix") {
      inherit system version;
    };
  verify =
    label: valid: result:
    builtins.trace "Checking ${system}: ${label}" (
      if valid then result else throw "Catalog contract: ${label}"
    );
  result =
    configuration:
    assert import ./ownership.nix { inherit (configuration) lib options; };
    configuration.config.system.build.toplevel.drvPath;
  installed =
    configuration: package:
    builtins.any (
      candidate: candidate.outPath == package.outPath
    ) configuration.config.environment.systemPackages;
  publicValues =
    configuration:
    builtins.toJSON {
      inherit (configuration.config) limanix;
      lmx = builtins.removeAttrs configuration.config.lmx [ "internal" ];
    };
  startup =
    configuration:
    let
      # Added packages change /etc and D-Bus restart-trigger hashes without adding startup commands.
      generated = builtins.toJSON {
        units = builtins.mapAttrs (_: unit: {
          inherit (unit) enable text;
        }) configuration.config.systemd.units;
        activation = configuration.config.system.activationScripts.script;
      };
    in
    lib.replaceStrings
      [
        (toString configuration.config.system.build.etc)
        configuration.config.systemd.services.dbus-broker.unitConfig."X-Restart-Triggers"
      ]
      [ "<generated-etc>" "<dbus-restart-triggers>" ]
      generated;
  sameResult =
    original: repeated:
    result original == result repeated && publicValues original == publicValues repeated;
  packagePriority = package: package.meta.priority or lib.meta.defaultPriority;
  installedAsDeclared =
    configuration: package:
    builtins.any (
      candidate:
      candidate.outPath == package.outPath && packagePriority candidate == packagePriority package
    ) configuration.config.environment.systemPackages;
  selectedPackage =
    configuration: package:
    let
      candidates = builtins.filter (
        candidate: (candidate.pname or null) == (package.pname or null)
      ) configuration.config.environment.systemPackages;
      matching = builtins.filter (candidate: candidate.outPath == package.outPath) candidates;
    in
    matching != [ ]
    && builtins.all (
      candidate:
      candidate.outPath == package.outPath
      || builtins.any (winner: packagePriority winner < packagePriority candidate) matching
    ) candidates;
  capability = configuration: configuration.config.lmx.capabilities.languageSupport;
  thirdParty = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.gopls ];
    lmx.capabilities.languageSupport = {
      tools.gopls = {
        package = pkgs.gopls;
        command = "${pkgs.gopls}/bin/gopls";
        args = [ "-rpc.trace" ];
        languages = [ "go" ];
      };
      languages.go.parsers = [ "go" ];
    };
  };
  thirdPartyConfiguration = configurationFor [ thirdParty ];
  providerCheck =
    name: identity:
    let
      module = entry name;
      versions = builtins.sort (left: right: lib.versionOlder left.version right.version) module.variants;
      newest = lib.last versions;
      tools = toolsFor name newest.version;
      expected = tools.${identity};
      original = configurationFor (map (variant: variant.path) versions);
      reversed = configurationFor (map (variant: variant.path) (lib.reverseList versions));
      declaration = (capability original).tools.${identity};
      reverseDeclaration = (capability reversed).tools.${identity};
      replacement = (toolsFor name (builtins.head versions).version).${identity};
      override = {
        lmx.capabilities.languageSupport.tools.${identity} = {
          package = replacement;
          command = "${replacement}/bin/${identity}";
          args = [ "--catalog-override" ];
          languages = [ "override-language" ];
        };
      };
      overridden = configurationFor ((map (variant: variant.path) versions) ++ [ override ]);
      actual = (capability overridden).tools.${identity};
      forced = configurationFor (
        (map (variant: variant.path) versions)
        ++ [
          ({ lib, ... }: {
            lmx.capabilities.languageSupport.tools.${identity} = lib.mkForce {
              package = replacement;
              command = "${replacement}/bin/${identity}";
            };
          })
        ]
      );
      explicitOnly = configurationFor [ newest.path ];
      defaultWithExplicit = configurationFor [
        module.path
        newest.path
      ];
      explicitWithDefault = configurationFor [
        newest.path
        module.path
      ];
    in
    {
      defaultEntryPoint = verify "${name} default and explicit default line use the same entry point" (
        sameResult explicitOnly defaultWithExplicit && sameResult explicitOnly explicitWithDefault
      ) (result explicitOnly);
      selection = verify "${name} declarations and package precedence select the same newest tool" (
        declaration.package.outPath == expected.outPath
        && packagePriority declaration.package == lib.meta.defaultPriority - (builtins.length versions - 1)
        && installedAsDeclared original declaration.package
        && declaration.command == "${expected}/bin/${identity}"
        && selectedPackage original expected
        && builtins.toJSON declaration == builtins.toJSON reverseDeclaration
        && selectedPackage reversed expected
        && !original.config.programs.neovim.enable
      ) (result original);
      userOverride =
        verify "ordinary definitions replace the complete ${identity} declaration and profile package"
          (
            actual.package.outPath == replacement.outPath
            && actual.command == "${replacement}/bin/${identity}"
            && actual.args == [ "--catalog-override" ]
            && actual.languages == [ "override-language" ]
            && selectedPackage overridden replacement
            && installedAsDeclared overridden replacement
          )
          (result overridden);
      forceOverride =
        verify "mkForce replaces the complete ${identity} declaration including optional fields"
          (
            (capability forced).tools.${identity}.package.outPath == replacement.outPath
            && (capability forced).tools.${identity}.args == [ ]
            && (capability forced).tools.${identity}.languages == [ ]
            && selectedPackage forced replacement
            && installedAsDeclared forced replacement
          )
          (result forced);
    };
in
{
  shared = import ./shared.nix { inherit nixpkgs system; };
  sharedDeclarations = import ./shared-tests.nix { inherit nixpkgs system; };
  ownership = import ./ownership-tests.nix { inherit nixpkgs system; };
  smokeRequirements = import ./smoke-requirements-tests.nix;
  componentDiscovery = import ./component-imports-tests.nix { inherit lib; };
  isolatedDefaults = {
    minikubeStartup =
      let
        configuration = configurationFor [ (path "minikube") ];
      in
      verify "Minikube selection does not add startup units or activation commands" (
        startup configuration == startup empty
      ) (result configuration);
    optionalDocker = builtins.listToAttrs (
      map
        (
          name:
          let
            configuration = configurationFor [ (path name) ];
          in
          {
            inherit name;
            value = verify "${name} does not implicitly enable Docker" (
              !configuration.config.virtualisation.docker.enable
            ) (result configuration);
          }
        )
        [
          "lazydocker"
          "minikube"
        ]
    );
    postgres =
      let
        configuration = configurationFor [ (path "postgres") ];
      in
      verify "PostgreSQL command selection does not enable the database service" (
        !configuration.config.services.postgresql.enable
        && !(configuration.config.systemd.services ? postgresql)
        && startup configuration == startup empty
      ) (result configuration);
    postgresService =
      let
        selected = builtins.head (entry "postgres").variants;
        tools = toolsFor "postgres" selected.version;
        configuration = configurationFor [
          selected.path
          {
            services.postgresql = {
              enable = true;
              package = pkgs.postgresql_18;
            };
          }
        ];
      in
      verify "catalog PostgreSQL commands outrank the independently selected service package" (
        configuration.config.services.postgresql.enable
        && configuration.config.services.postgresql.package.outPath == pkgs.postgresql_18.outPath
        && selectedPackage configuration tools.postgres
      ) (result configuration);
  };
  emptyCapabilities = verify "public capabilities exist without selecting catalog modules" (
    (capability empty).tools == { }
    && (capability empty).languages == { }
    && !empty.config.programs.neovim.enable
    && !empty.config.programs.tmux.enable
    && !empty.config.programs.zsh.enable
  ) (result empty);
  thirdPartyCapabilities =
    verify "a third-party provider declares tools and languages without catalog imports"
      (
        (capability thirdPartyConfiguration).tools.gopls.package.outPath == pkgs.gopls.outPath
        && (capability thirdPartyConfiguration).tools.gopls.command == "${pkgs.gopls}/bin/gopls"
        && (capability thirdPartyConfiguration).tools.gopls.args == [ "-rpc.trace" ]
        && (capability thirdPartyConfiguration).languages.go.parsers == [ "go" ]
        && installed thirdPartyConfiguration pkgs.gopls
        && !thirdPartyConfiguration.config.programs.neovim.enable
      )
      (result thirdPartyConfiguration);
  thirdPartyConsumer =
    let
      configuration = configurationFor [
        (path "astronvim")
        thirdParty
      ];
    in
    verify "AstroNvim accepts a third-party declaration for its supported gopls identity" (
      configuration.config.programs.neovim.enable
      &&
        builtins.toJSON (capability configuration).tools
        == builtins.toJSON (capability thirdPartyConfiguration).tools
      && installed configuration pkgs.gopls
    ) (result configuration);
  parserOnly =
    let
      configuration = configurationFor [
        {
          lmx.capabilities.languageSupport.languages.example.parsers = [ "lua" ];
        }
      ];
    in
    verify "a parser-only language needs no tool, package, command, or consumer" (
      (capability configuration).tools == { }
      && (capability configuration).languages.example.parsers == [ "lua" ]
      && !configuration.config.programs.neovim.enable
      && configuration.config.environment.systemPackages == empty.config.environment.systemPackages
    ) (result configuration);
  parserProviders = builtins.listToAttrs (
    map
      (
        name:
        let
          configuration = configurationFor [ (path name) ];
        in
        {
          inherit name;
          value = verify "${name} contributes parsers without a language server or consumer" (
            (capability configuration).tools == { }
            && (capability configuration).languages != { }
            && !configuration.config.programs.neovim.enable
          ) (result configuration);
        }
      )
      [
        "nodejs"
        "python"
      ]
  );
  languageContributions =
    let
      configuration = configurationFor [
        { lmx.capabilities.languageSupport.languages.go.parsers = [ "go" ]; }
        {
          lmx.capabilities.languageSupport.languages = {
            go.parsers = [ "gomod" ];
            python.parsers = [ "python" ];
          };
        }
      ];
    in
    verify "language contributions coexist through normal list and attribute merging" (
      builtins.sort builtins.lessThan (capability configuration).languages.go.parsers == [
        "go"
        "gomod"
      ]
      && (capability configuration).languages.python.parsers == [ "python" ]
      && (capability configuration).tools == { }
    ) (result configuration);
  consumerIndependence =
    let
      configuration = configurationFor [ (path "astronvim") ];
    in
    verify "AstroNvim alone does not install optional language providers" (
      (capability configuration).tools == { }
      && (capability configuration).languages == { }
      &&
        builtins.all
          (
            provider:
            let
              tools = toolsFor provider.name (entry provider.name).version;
            in
            builtins.all (packageName: !(installed configuration tools.${packageName})) provider.packages
          )
          [
            {
              name = "go";
              packages = [
                "go"
                "gopls"
                "delve"
              ];
            }
            {
              name = "rust";
              packages = [
                "rustc"
                "cargo"
                "rust-analyzer"
              ];
            }
            {
              name = "nodejs";
              packages = [ "nodejs" ];
            }
            {
              name = "python";
              packages = [
                "python"
                "virtualenv"
              ];
            }
          ]
    ) (result configuration);
  equalToolDeclarations =
    let
      declaration = {
        package = pkgs.hello;
        command = "${pkgs.hello}/bin/hello";
        args = [
          "--greeting"
          "hello"
        ];
        languages = [ "example" ];
      };
      configuration = configurationFor [
        { lmx.capabilities.languageSupport.tools.example = lib.mkDefault declaration; }
        { lmx.capabilities.languageSupport.tools.example = lib.mkDefault declaration; }
      ];
    in
    verify "identical complete tool declarations do not duplicate lists" (
      (capability configuration).tools.example == declaration
    ) (result configuration);
  equalToolDeclarationDefaults =
    let
      required = {
        package = pkgs.hello;
        command = "${pkgs.hello}/bin/hello";
      };
      configuration = configurationFor [
        { lmx.capabilities.languageSupport.tools.example = lib.mkDefault required; }
        {
          lmx.capabilities.languageSupport.tools.example = lib.mkDefault (
            required
            // {
              args = [ ];
              languages = [ ];
            }
          );
        }
      ];
    in
    verify "omitted and explicit tool defaults are equal declarations" (
      (capability configuration).tools.example == required
      // {
        args = [ ];
        languages = [ ];
      }
    ) (result configuration);
  completeDeclaration =
    let
      weak = { lib, pkgs, ... }: {
        environment.systemPackages = [ pkgs.hello ];
        lmx.capabilities.languageSupport.tools.example = lib.mkOverride 1000 {
          package = pkgs.hello;
          command = "${pkgs.hello}/bin/hello";
          args = [ "discarded" ];
          languages = [ "discarded" ];
        };
      };
      conflictingWeak = { lib, pkgs, ... }: {
        lmx.capabilities.languageSupport.tools.example = lib.mkOverride 1000 {
          package = pkgs.hello;
          command = "${pkgs.hello}/bin/hello";
          args = [ "also-discarded" ];
        };
      };
      strong = { lib, pkgs, ... }: {
        environment.systemPackages = [ pkgs.coreutils ];
        lmx.capabilities.languageSupport.tools.example = lib.mkOverride 999 {
          package = pkgs.coreutils;
          command = "${pkgs.coreutils}/bin/true";
        };
      };
      configuration = configurationFor [
        weak
        conflictingWeak
        strong
      ];
      reversed = configurationFor [
        strong
        conflictingWeak
        weak
      ];
      declaration = (capability configuration).tools.example;
    in
    verify "precedence selects a complete tool declaration before optional fields merge" (
      declaration.package.outPath == pkgs.coreutils.outPath
      && declaration.command == "${pkgs.coreutils}/bin/true"
      && declaration.args == [ ]
      && declaration.languages == [ ]
      && builtins.toJSON declaration == builtins.toJSON (capability reversed).tools.example
    ) (result configuration);
  providers = {
    go = providerCheck "go" "gopls";
    rust = providerCheck "rust" "rust-analyzer";
  };
  versionSelection =
    lib.mapAttrs
      (
        name: packageNames:
        let
          module = entry name;
          versions = builtins.sort (left: right: lib.versionOlder left.version right.version) module.variants;
          newest = lib.last versions;
          expected = toolsFor name newest.version;
          original = configurationFor (map (variant: variant.path) versions);
          reversed = configurationFor (map (variant: variant.path) (lib.reverseList versions));
        in
        verify "${name} coexistence selects newest ordinary packages regardless of import order" (
          builtins.all
          (
            packageName:
            selectedPackage original expected.${packageName} && selectedPackage reversed expected.${packageName}
          )
          packageNames
        ) (result original)
      )
      {
        go = [
          "go"
          "gopls"
          "delve"
        ];
        helm = [ "helm" ];
        k9s = [ "k9s" ];
        minikube = [ "minikube" ];
        nodejs = [ "nodejs" ];
        postgres = [ "postgres" ];
        python = [
          "python"
          "virtualenv"
        ];
        rust = [
          "rustc"
          "cargo"
          "rustfmt"
          "clippy"
          "rust-analyzer"
        ];
        terraform = [ "terraform" ];
      };
  repeatImports = builtins.listToAttrs (
    map (
      module:
      let
        original = configurationFor [ module.path ];
        repeated = configurationFor [
          module.path
          module.path
        ];
      in
      {
        inherit (module) name;
        value =
          verify "${module.name} repeat imports preserve the system and public options"
            (sameResult original repeated)
            (result original);
      }
    ) catalog
  );
  componentImports = builtins.listToAttrs (
    map (
      selected:
      let
        original = configurationFor [ selected.path ];
        components = import ./component-imports.nix {
          inherit catalog selected;
          inherit (original) graph;
        };
        repeated = configurationFor ([ selected.path ] ++ components);
      in
      {
        inherit (selected) name;
        # Keep selector names lazy: CI discovers them before evaluating each leaf.
        value =
          if components == [ ] then
            true
          else
            verify "${selected.name} with repeated components preserves the system and public options"
              (sameResult original repeated)
              (result original);
      }
    ) (builtins.concatMap (module: [ module ] ++ module.variants) catalog)
  );
  options = {
    neovimEditor =
      let
        original = configurationFor [ (path "neovim") ];
        overridden = configurationFor [
          (path "neovim")
          { programs.neovim.defaultEditor = true; }
        ];
      in
      verify "Neovim retains its default editor setting and supports the documented override" (
        !original.config.programs.neovim.defaultEditor && overridden.config.programs.neovim.defaultEditor
      ) (result overridden);
    astronvimDefaults =
      let
        configuration = configurationFor [
          (path "astronvim")
          {
            programs.neovim.defaultEditor = false;
            programs.nix-ld.enable = false;
          }
        ];
      in
      verify "AstroNvim supports ordinary editor and nix-ld overrides" (
        !configuration.config.programs.neovim.defaultEditor
        && !configuration.config.programs.nix-ld.enable
        && configuration.config.programs.neovim.enable
      ) (result configuration);
    cliToolsPreferences =
      let
        original = configurationFor [ (path "cli-tools") ];
        configuration = configurationFor [
          (path "cli-tools")
          {
            programs.git.config.core.pager = "cat";
            programs.git.config.interactive.diffFilter = "cat";
          }
        ];
        settings = builtins.head configuration.config.programs.git.config;
        defaults = builtins.head original.config.programs.git.config;
      in
      verify "CLI tools support ordinary Git pager and diff-filter overrides" (
        defaults.core.pager == "${pkgs.delta}/bin/delta"
        && defaults.interactive.diffFilter == "${pkgs.delta}/bin/delta --color-only"
        && settings.core.pager == "cat"
        && settings.interactive.diffFilter == "cat"
      ) (result configuration);
    tmuxPreferences =
      let
        original = configurationFor [ (path "tmux") ];
        overridden = configurationFor [
          (path "tmux")
          {
            programs.tmux = {
              keyMode = "emacs";
              terminal = "screen-256color";
              escapeTime = 25;
            };
          }
        ];
      in
      verify "Tmux defaults and ordinary preference overrides" (
        original.config.programs.tmux.keyMode == "vi"
        && original.config.programs.tmux.terminal == "tmux-256color"
        && original.config.programs.tmux.escapeTime == 10
        && overridden.config.programs.tmux.keyMode == "emacs"
        && overridden.config.programs.tmux.terminal == "screen-256color"
        && overridden.config.programs.tmux.escapeTime == 25
      ) (result overridden);
    tmuxNavigation =
      let
        original = configurationFor [ (path "tmux") ];
        disabled = configurationFor [
          (path "tmux")
          { lmx.tmux.navigation.enable = false; }
        ];
        text = configuration: configuration.config.environment.etc."tmux.conf".text;
        bindings =
          lib.concatMap
            (key: [
              "bind -n C-${key} "
              "bind -n M-${key} "
              "bind C-${key} send-keys "
            ])
            [
              "h"
              "j"
              "k"
              "l"
            ];
      in
      verify "Tmux navigation switch changes only documented navigation bindings" (
        original.config.lmx.tmux.navigation.enable
        && !disabled.config.lmx.tmux.navigation.enable
        && builtins.all (
          binding: lib.hasInfix binding (text original) && !lib.hasInfix binding (text disabled)
        ) bindings
        && lib.hasInfix "set -g mouse on" (text disabled)
        && lib.hasInfix "set -s set-clipboard on" (text disabled)
        && original.config.programs.tmux.plugins == disabled.config.programs.tmux.plugins
      ) (result disabled);
    zshShell =
      let
        original = configurationFor [ (path "zsh") ];
        overridden = configurationFor [
          (path "zsh")
          { limanix.user.shell = pkgs.bashInteractive; }
        ];
      in
      verify "Zsh defaults the account shell and supports an ordinary Bash override" (
        original.config.limanix.user.shell == pkgs.zsh
        && overridden.config.limanix.user.shell == pkgs.bashInteractive
        && overridden.config.users.users.${userName}.shell == pkgs.bashInteractive
        && overridden.config.programs.zsh.enable
      ) (result overridden);
    zshPreferences =
      let
        original = configurationFor [ (path "zsh") ];
        overridden = configurationFor [
          (path "zsh")
          {
            programs = {
              starship.settings = {
                hostname.ssh_only = true;
                status.disabled = true;
              };
              atuin.settings = {
                auto_sync = true;
                update_check = true;
              };
            };
          }
        ];
      in
      verify "Zsh prompt and history preferences support ordinary overrides" (
        !original.config.programs.starship.settings.hostname.ssh_only
        && !original.config.programs.starship.settings.status.disabled
        && !original.config.programs.atuin.settings.auto_sync
        && !original.config.programs.atuin.settings.update_check
        && overridden.config.programs.starship.settings.hostname.ssh_only
        && overridden.config.programs.starship.settings.status.disabled
        && overridden.config.programs.atuin.settings.auto_sync
        && overridden.config.programs.atuin.settings.update_check
      ) (result overridden);
  };
}
