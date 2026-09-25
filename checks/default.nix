let
  catalog = import ./catalog.nix ../modules;
  variants = builtins.concatMap (module: module.variants) catalog;
  nixpkgs = import ./nixpkgs.nix;
  systems = {
    arm64 = "aarch64-linux";
    amd64 = "x86_64-linux";
  };

  checkSystem =
    arch: system:
    let
      checkResult =
        config: selected:
        let
          parent = builtins.dirOf selected.path;
          versioned = builtins.baseNameOf parent == "versions";
          directory = if versioned then builtins.dirOf parent else parent;
          name = builtins.baseNameOf directory;
          metadata = builtins.fromTOML (builtins.readFile (directory + "/module.toml"));
          version =
            if versioned then
              builtins.replaceStrings [ ".nix" ] [ "" ] (builtins.baseNameOf selected.path)
            else
              metadata.default;
          tools = import (directory + "/packages.nix") { inherit version system; };
          package = tools.${if name == "rust" then "rustc" else name};
          valid =
            if
              builtins.elem name [
                "git"
                "neovim"
              ]
            then
              config.programs.${name}.enable
            else if name == "docker" then
              config.virtualisation.docker.enable
              && config.virtualisation.docker.package.outPath == package.outPath
              && builtins.elem "docker" config.users.users.dev.extraGroups
            else
              builtins.any (installed: installed.outPath == package.outPath) config.environment.systemPackages;
        in
        if valid then
          true
        else
          throw "Module result: ${selected.name} does not match its expected packages or program/service settings";
      evaluate =
        label: selected:
        let
          configuration = import ./nixos.nix {
            inherit nixpkgs arch system;
            modules = builtins.map (module: module.path) selected;
          };
        in
        builtins.trace "Checking ${system}: ${label}" (
          builtins.addErrorContext "while checking ${label} on ${system}" (
            assert builtins.all (checkResult configuration.config) selected;
            configuration.config.system.build.toplevel.drvPath
          )
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
      versions = builtins.listToAttrs (
        builtins.map (variant: {
          inherit (variant) name;
          value = evaluate variant.name [ variant ];
        }) variants
      );
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
    };
in
builtins.deepSeq catalog (builtins.mapAttrs checkSystem systems)
