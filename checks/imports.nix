{
  catalog,
  graph,
}:
let
  root = toString (builtins.dirOf (builtins.head catalog).directory) + "/";
  hasPrefix = prefix: value: builtins.substring 0 (builtins.stringLength prefix) value == prefix;
  directoryFor =
    key:
    builtins.head (
      builtins.split "/" (builtins.substring (builtins.stringLength root) (builtins.stringLength key) key)
    );
  entryPoints = map (entry: toString entry.path) (
    builtins.concatMap (module: [ module ] ++ module.variants) catalog
  );
  concreteCatalogImport = key: hasPrefix root key && builtins.pathExists key;
  active = nodes: builtins.filter (node: !node.disabled) nodes;
  nodes = builtins.genericClosure {
    startSet = active graph;
    operator = node: active node.imports;
  };
in
builtins.all (
  node:
  builtins.all (
    child:
    child.disabled
    # Inline nodes retain their containing module path in the graph key.
    || !hasPrefix root node.key
    || !concreteCatalogImport child.key
    || (
      builtins.match ".*[.]nix" child.key != null
      && (
        directoryFor child.key == directoryFor node.key
        || directoryFor child.key == "_shared"
        || builtins.elem child.key entryPoints
      )
    )
    || throw "Catalog import boundary: ${node.key} imports ${child.key}; import a concrete component entry point"
  ) node.imports
) nodes
