{
  modules ? "[]",
}:
let
  system = builtins.currentSystem;
  catalog = import ./catalog.nix ../catalog;
  requested = builtins.fromJSON modules;
  names = map (module: module.name) catalog;
  require = condition: message: if condition then true else throw "Module checks: ${message}";
  selectedNames = if requested == [ ] then names else requested;
  selected = builtins.filter (module: builtins.elem module.name selectedNames) catalog;
  contexts = map (
    module:
    import ./module.nix {
      inherit catalog module system;
      nixpkgs = import ./nixpkgs.nix;
      userName = "module-check";
    }
  ) selected;
  evaluation = builtins.listToAttrs (
    map (context: {
      name = context.module.name;
      value = context.evaluation;
    }) contexts
  );
  smoke = builtins.concatMap (context: import ./module-smoke.nix context) contexts;
in
assert require (builtins.elem system [
  "aarch64-linux"
  "x86_64-linux"
]) "a native Linux runner is required";
assert require (
  builtins.isList requested && builtins.all builtins.isString requested
) "modules must be a JSON array of module names";
assert require (builtins.all (name: builtins.elem name names) requested) "unknown module name";
builtins.deepSeq catalog {
  inherit system evaluation smoke;
  names = map (module: module.name) selected;
  all = builtins.deepSeq evaluation smoke;
  diagnostics = builtins.listToAttrs (
    builtins.concatMap (
      context:
      map (name: {
        name = "${context.module.name}.${name}";
        value = context.diagnostics.${name};
      }) (builtins.attrNames context.diagnostics)
    ) contexts
  );
}
