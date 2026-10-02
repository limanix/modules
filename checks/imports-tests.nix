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
  leaf = root + "/leaf/default.nix";
  component = root + "/component/default.nix";
  node = key: imports: {
    inherit imports;
    key = toString key;
    disabled = false;
  };
  check = graph: import ./imports.nix { inherit catalog graph; };
  rejects = graph: !(builtins.tryEval (check graph)).success;
  cycle = rec {
    parent = node component [ child ];
    child = node leaf [ parent ];
  };
in
assert check (lib.evalModules { modules = [ (builtins.head catalog).path ]; }).graph;
assert check [ (node component [ (node leaf [ ]) ]) ];
assert check [ cycle.parent ];
assert check [ (node (toString component + ":anon-1") [ (node leaf [ ]) ]) ];
assert check [
  (node (toString (root + "/aggregate/default.nix") + ":anon-1") [
    (node (root + "/aggregate/private.nix") [ ])
  ])
];
assert rejects [
  (node (toString component + ":anon-1") [ (node (root + "/aggregate/private.nix") [ ]) ])
];
assert check [ (node component [ ((node (root + "/leaf") [ ]) // { disabled = true; }) ]) ];
assert check [ (node component [ (node (toString component + ":anon-1") [ ]) ]) ];
assert check [
  (node (root + "/aggregate/default.nix") [ (node (root + "/aggregate/versions/1.nix") [ ]) ])
];
assert rejects [ (node component [ (node (root + "/leaf") [ ]) ]) ];
assert rejects [ (node component [ (node (root + "/aggregate/private.nix") [ ]) ]) ];
true
