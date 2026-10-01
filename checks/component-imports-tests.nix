{ lib }:
let
  root = ./fixtures/component-imports;
  catalog =
    map
      (name: rec {
        inherit name;
        directory = root + "/${name}";
        path = directory + "/default.nix";
        variants = lib.optional (name == "aggregate") {
          inherit directory;
          name = "aggregate-1";
          path = directory + "/versions/1.nix";
        };
      })
      [
        "aggregate"
        "component"
        "leaf"
        "extra"
      ];
  aggregate = builtins.head catalog;
  version = builtins.head aggregate.variants;
  discover =
    selected: extraModules:
    import ./component-imports.nix {
      inherit catalog selected;
      inherit (lib.evalModules { modules = [ selected.path ] ++ extraModules; }) graph;
    };
  component = root + "/component/default.nix";
  leaf = root + "/leaf/default.nix";
  extra = root + "/extra/default.nix";
in
assert
  discover aggregate [ ] == [
    component
    leaf
  ];
assert
  discover version [ ] == [
    extra
    component
    leaf
  ];
assert discover aggregate [ { disabledModules = [ component ]; } ] == [ ];
assert
  discover aggregate [
    { disabledModules = [ component ]; }
    leaf
  ] == [ leaf ];
assert
  discover aggregate [ component ] == [
    component
    leaf
  ];
true
