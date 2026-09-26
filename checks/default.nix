let
  catalog = import ./catalog.nix ../catalog;
  variants = builtins.concatMap (module: module.variants) catalog;
  nixpkgs = import ./nixpkgs.nix;
  userName = "module-check";
  systems = {
    arm64 = "aarch64-linux";
    amd64 = "x86_64-linux";
  };

  checkSystem =
    arch: system:
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
            arch
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
      versions = versionChecks;
      combinations = builtins.listToAttrs (
        builtins.concatMap (
          module:
          builtins.map (variant: {
            inherit (variant) name;
            value = evaluate "all modules with ${variant.name}" (
              builtins.map (selected: if selected.name == module.name then variant else selected) catalog
            );
          }) module.variants
        ) catalog
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
