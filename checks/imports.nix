# Graph enforcement covers module imports; ordinary import/readFile need review.
{ catalog, graph }:
let
  root = toString (builtins.dirOf (builtins.head catalog).directory) + "/";
  hasPrefix = prefix: value: builtins.substring 0 (builtins.stringLength prefix) value == prefix;
  relative = key: builtins.substring (builtins.stringLength root) (builtins.stringLength key) key;
  directoryFor = key: builtins.head (builtins.split "/" (relative key));
  sharedSchema =
    key:
    builtins.match "_shared/[^/]+[.]nix" (relative key) != null && relative key != "_shared/test.nix";
  entryPoints = builtins.concatMap (
    module:
    [ (toString module.path) ]
    ++ map (line: toString (module.directory + "/versions/${line}.nix")) module.lines
  ) catalog;
  concreteCatalogImport = key: hasPrefix root key && builtins.pathExists key;
  active = nodes: builtins.filter (node: !(node.disabled or false)) nodes;
  nodes = builtins.genericClosure {
    startSet = active graph;
    operator = node: active node.imports;
  };
in
builtins.all (
  node:
  builtins.all (
    child:
    (child.disabled or false)
    || !hasPrefix root node.key
    || !concreteCatalogImport child.key
    || (
      builtins.match ".*[.]nix" child.key != null
      && (
        sharedSchema child.key
        || (
          directoryFor node.key != "_shared"
          && (directoryFor child.key == directoryFor node.key || builtins.elem child.key entryPoints)
        )
      )
    )
    || throw "Catalog import boundary: ${node.key} imports ${child.key}; use a public entry point"
  ) node.imports
) nodes
