{
  system ? builtins.currentSystem,
}:
let
  catalog = import ./catalog.nix ../catalog;
  nixpkgs = import ./nixpkgs.nix;
  lib = import (nixpkgs + "/lib");
  userName = "module-check";
  evaluateStandalone =
    modules:
    import ./nixos.nix {
      inherit
        nixpkgs
        system
        userName
        modules
        ;
    };
  checkModule =
    module:
    let
      smoke = builtins.dirOf module.path + "/smoke.nix";
      checkSelection =
        selected:
        let
          evaluate = extraModules: evaluateStandalone ([ selected.path ] ++ extraModules);
          configuration = evaluate [ ];
          hasPackage =
            package:
            builtins.any (
              installed: installed.outPath == package.outPath
            ) configuration.config.environment.systemPackages;
          checks = import smoke {
            inherit (configuration) config pkgs;
            inherit
              lib
              userName
              hasPackage
              evaluate
              evaluateStandalone
              ;
            inherit (selected) version;
            selector = selected.name;
          };
        in
        assert
          builtins.isAttrs checks && checks != { }
          || throw "Module smoke: ${selected.name} must return a nonempty attribute set";
        {
          inherit (selected) name;
          value = builtins.mapAttrs (
            name: check:
            assert
              lib.isDerivation check || throw "Module smoke: ${selected.name}.${name} must be a derivation";
            assert
              check.system == system
              || throw "Module smoke: ${selected.name}.${name} targets ${check.system}, expected ${system}";
            check
          ) checks;
        };
    in
    if builtins.pathExists smoke then
      builtins.map checkSelection ([ module ] ++ module.variants)
    else
      [ ];
in
builtins.listToAttrs (builtins.concatMap checkModule catalog)
