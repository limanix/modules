{
  catalog,
  selected,
  graph,
}:
let
  # Graph keys identify imports; file names can be replaced by diagnostic _file labels.
  active = nodes: builtins.filter (node: !node.disabled) nodes;
  imported = map (node: node.key) (
    builtins.genericClosure {
      startSet = active graph;
      operator = node: active node.imports;
    }
  );
  siblings = builtins.filter (module: module.directory != selected.directory) catalog;
  entryPoints = builtins.listToAttrs (
    map (module: {
      name = toString module.path;
      value = module.path;
    }) (builtins.concatMap (module: [ module ] ++ module.variants) siblings)
  );
in
# Preserve Nix's traversal order; sorting components also reorders merged package lists.
map (key: entryPoints.${key}) (builtins.filter (key: builtins.hasAttr key entryPoints) imported)
