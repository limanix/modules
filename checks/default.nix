let
  catalog = import ./catalog.nix ../catalog;
  variants = builtins.concatMap (module: module.variants) catalog;
  multiVersionModules = builtins.filter (
    module:
    builtins.elem module.name [
      "go"
      "helm"
      "k9s"
      "minikube"
      "nodejs"
      "postgres"
      "python"
      "rust"
      "terraform"
    ]
  ) catalog;
  nixpkgs = import ./nixpkgs.nix;
  userName = "module-check";
  systems = {
    arm64 = "aarch64-linux";
    amd64 = "x86_64-linux";
  };

  checkSystem =
    _: system:
    let
      checkResult =
        configuration: selected:
        let
          hasPackage =
            package:
            builtins.any (
              installed: installed.outPath == package.outPath
            ) configuration.config.environment.systemPackages;
          valid = import selected.check {
            inherit (configuration) config pkgs;
            inherit (selected) version;
            inherit userName hasPackage;
          };
        in
        if valid then
          true
        else
          throw "Module result: ${selected.name} does not match its expected packages or program/service settings";
      configurationFor =
        selected:
        import ./nixos.nix {
          inherit
            nixpkgs
            system
            userName
            ;
          modules = builtins.map (module: module.path) selected;
        };
      evaluate =
        label: selected:
        let
          configuration = configurationFor selected;
        in
        builtins.trace "Checking ${system}: ${label}" (
          builtins.addErrorContext "while checking ${label} on ${system}" (
            assert import ./ownership.nix { inherit (configuration) lib options; };
            assert builtins.all (checkResult configuration) selected;
            configuration.config.system.build.toplevel.drvPath
          )
        );
      versionChecks = builtins.listToAttrs (
        builtins.map (variant: {
          inherit (variant) name;
          value = evaluate variant.name [ variant ];
        }) variants
      );
    in
    {
      individual = builtins.listToAttrs (
        builtins.map (module: {
          inherit (module) name;
          value = evaluate module.name [ module ];
        }) catalog
      );
      combined = evaluate "all modules" catalog;
      contracts = import ./contracts.nix {
        inherit
          catalog
          nixpkgs
          system
          userName
          ;
      };
      consoleComposition =
        let
          console = builtins.head (builtins.filter (module: module.name == "console") catalog);
          configuration = configurationFor [ console ];
          components = builtins.map (
            path: builtins.head (builtins.filter (module: module.path == path) catalog)
          ) (import ../catalog/console/components.nix);
          # Evaluate both user selections independently; extendModules changes module ordering.
          extended = configurationFor ([ console ] ++ components);
          original = configuration.config.system.build.toplevel.drvPath;
        in
        builtins.trace "Checking ${system}: console with its components" (
          builtins.addErrorContext "while checking console composition on ${system}" (
            assert checkResult configuration console;
            assert checkResult extended console;
            assert
              original == extended.config.system.build.toplevel.drvPath
              || throw "Console composition changes the system result when components are selected again";
            original
          )
        );
      consoleContracts =
        let
          console = builtins.head (builtins.filter (module: module.name == "console") catalog);
          configuration = configurationFor [ console ];
          inherit (configuration) lib pkgs;
          verify =
            label: valid: result:
            builtins.trace "Checking ${system}: ${label}" (
              builtins.addErrorContext "while checking ${label} on ${system}" (
                if valid then result else throw "Console contract: ${label}"
              )
            );
          rejectsIdentityDefinition =
            name:
            let
              original = configuration.config.limanix.user.${name};
              extended = configuration.extendModules {
                # Even an identical second definition must fail for a read-only option.
                modules = [ { limanix.user.${name} = original; } ];
              };
            in
            builtins.deepSeq original (!(builtins.tryEval extended.config.limanix.user.${name}).success);
        in
        {
          bashOverride =
            let
              extended = configuration.extendModules {
                modules = [ { limanix.user.shell = pkgs.bashInteractive; } ];
              };
            in
            verify "console accepts a Bash login-shell override" (
              extended.config.limanix.user.shell == pkgs.bashInteractive
              && extended.config.users.users.${userName}.shell == pkgs.bashInteractive
              && extended.config.programs.zsh.enable
            ) extended.config.system.build.toplevel.drvPath;
          navigationOverride =
            let
              extended = configuration.extendModules {
                modules = [ { lmx.tmux.navigation.enable = false; } ];
              };
              original = configuration.config.environment.etc."tmux.conf".text;
              actual = extended.config.environment.etc."tmux.conf".text;
              bindings =
                builtins.concatMap
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
            verify "console disables custom navigation without removing tmux features" (
              !extended.config.lmx.tmux.navigation.enable
              && extended.config.programs.tmux.enable
              && extended.config.programs.tmux.keyMode == "vi"
              && extended.config.programs.tmux.plugins == configuration.config.programs.tmux.plugins
              && builtins.all (binding: lib.hasInfix binding original && !lib.hasInfix binding actual) bindings
              && lib.hasInfix "set -g mouse on" actual
            ) extended.config.system.build.toplevel.drvPath;
          readOnlyIdentity = verify "console user name and home reject another definition" (builtins.all
            rejectsIdentityDefinition
            [
              "name"
              "home"
            ]
          ) true;
        };
      astronvimVersionSelection =
        let
          astronvim = builtins.head (builtins.filter (module: module.name == "astronvim") catalog);
          console = builtins.head (builtins.filter (module: module.name == "console") catalog);
          selected = builtins.head (
            builtins.filter (variant: variant.version == astronvim.version) astronvim.variants
          );
          standalone = configurationFor [ selected ];
          withDefault = configurationFor [
            astronvim
            selected
          ];
          withConsole = configurationFor [
            console
            selected
          ];
          reversed = configurationFor [
            selected
            console
          ];
          overridden = withConsole.extendModules {
            modules = [
              ({ lib, ... }: {
                # An explicit line must also win when the recommended line changes.
                lmx.internal.astronvim.version = lib.mkDefault "unavailable";
              })
            ];
          };
          result = withConsole.config.system.build.toplevel.drvPath;
        in
        builtins.trace "Checking ${system}: explicit AstroNvim version with defaults and Console" (
          assert checkResult standalone selected;
          assert checkResult withConsole selected;
          assert checkResult reversed selected;
          assert
            standalone.config.system.build.toplevel.drvPath == withDefault.config.system.build.toplevel.drvPath;
          # Import order can reorder system package lists without changing the editor.
          assert
            withConsole.config.programs.neovim.finalPackage.drvPath
            == reversed.config.programs.neovim.finalPackage.drvPath;
          assert result == overridden.config.system.build.toplevel.drvPath;
          builtins.deepSeq reversed.config.system.build.toplevel.drvPath result
        );
      versions = versionChecks;
      multiVersion = builtins.listToAttrs (
        builtins.map (module: {
          inherit (module) name;
          value = evaluate "all ${module.name} versions" module.variants;
        }) multiVersionModules
      );
      minikubeK9sSelection =
        let
          minikube = builtins.head (builtins.filter (module: module.name == "minikube") catalog);
          k9s = builtins.head (builtins.filter (module: module.name == "k9s") catalog);
          selected = builtins.head k9s.variants;
          newest = builtins.head (builtins.filter (variant: variant.version == k9s.version) k9s.variants);
          configuration = configurationFor [
            minikube
            selected
          ];
          multiple = [
            minikube
            selected
            newest
          ];
          multipleConfiguration = configurationFor multiple;
          withDefault = configurationFor [
            minikube
            selected
            k9s
          ];
          packagesFor = version: import ../catalog/k9s/packages.nix { inherit version system; };
          recommended = (packagesFor k9s.version).k9s;
          explicit = (packagesFor selected.version).k9s;
          installedK9s =
            configuration:
            builtins.filter (
              candidate: (candidate.pname or null) == "k9s"
            ) configuration.config.environment.systemPackages;
          hasOnly =
            configuration: expected:
            let
              installed = installedK9s configuration;
            in
            builtins.length installed == builtins.length expected
            && builtins.all (
              package:
              builtins.length (builtins.filter (candidate: candidate.outPath == package.outPath) installed) == 1
            ) expected;
          priority =
            package:
            (builtins.head (
              builtins.filter (candidate: candidate.outPath == package.outPath) (
                installedK9s multipleConfiguration
              )
            )).meta.priority;
        in
        assert checkResult configuration minikube;
        assert checkResult configuration selected;
        assert hasOnly configuration [ explicit ];
        assert hasOnly withDefault [ explicit ];
        assert hasOnly multipleConfiguration [
          explicit
          recommended
        ];
        assert priority recommended < priority explicit;
        builtins.deepSeq
          (evaluate "Minikube with explicitly selected ${selected.name} and ${newest.name}" multiple)
          (
            evaluate "Minikube with explicitly selected ${selected.name}" [
              minikube
              selected
            ]
          );
      dockerVersionConflict =
        let
          dockerVersions =
            (builtins.head (builtins.filter (module: module.name == "docker") catalog)).variants;
          selected = [
            (builtins.elemAt dockerVersions 0)
            (builtins.elemAt dockerVersions 1)
          ];
          configuration = configurationFor selected;
        in
        assert
          builtins.length dockerVersions >= 2 || throw "Docker conflict check needs two declared versions";
        builtins.deepSeq (map (variant: versionChecks.${variant.name}) selected) (
          builtins.trace "Checking ${system}: Docker version conflict" (
            if (builtins.tryEval configuration.config.virtualisation.docker.package.outPath).success then
              throw "Module result: selecting two Docker versions must fail"
            else
              true
          )
        );
    };
in
builtins.deepSeq catalog (builtins.mapAttrs checkSystem systems)
