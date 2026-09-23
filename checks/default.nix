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
      evaluate =
        label: selected:
        let
          configuration = import ./nixos.nix {
            inherit nixpkgs arch system;
            modules = builtins.map (module: module.path) selected;
          };
        in
        builtins.trace "Checking ${system}: ${label}" (
          builtins.addErrorContext "while checking ${label} on ${system}" configuration.config.system.build.toplevel.drvPath
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
