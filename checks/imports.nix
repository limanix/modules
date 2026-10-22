# Graph enforcement covers module imports; ordinary import/readFile need review.
# A file belongs to the module whose directory contains it, whatever the depth of its kind.
{
  catalog,
  graph,
  root,
}:
let
  rootPrefix = toString root + "/";
  hasPrefix = prefix: value: builtins.substring 0 (builtins.stringLength prefix) value == prefix;
  relative =
    key: builtins.substring (builtins.stringLength rootPrefix) (builtins.stringLength key) key;
  sharedSchema =
    key:
    builtins.match "_shared/[^/]+[.]nix" (relative key) != null && relative key != "_shared/test.nix";
  ownerOf =
    key:
    let
      owners = builtins.filter (module: hasPrefix (toString module.directory + "/") key) catalog;
    in
    if hasPrefix (rootPrefix + "_shared/") key then
      "_shared"
    else if owners != [ ] then
      toString (builtins.head owners).directory
    else
      null;
  entryPoints = builtins.concatMap (
    module:
    [ (toString module.path) ]
    ++ map (line: toString (module.directory + "/versions/${line}.nix")) module.lines
  ) catalog;
  concreteCatalogImport = key: hasPrefix rootPrefix key && builtins.pathExists key;
  active = nodes: builtins.filter (node: !(node.disabled or false)) nodes;
  nodes = builtins.genericClosure {
    startSet = active graph;
    operator = node: active node.imports;
  };
in
builtins.all (
  node:
  let
    owner = ownerOf node.key;
  in
  builtins.all (
    child:
    (child.disabled or false)
    || !hasPrefix rootPrefix node.key
    || !concreteCatalogImport child.key
    || (
      builtins.match ".*[.]nix" child.key != null
      && (
        sharedSchema child.key
        || (
          owner != null
          && owner != "_shared"
          && (ownerOf child.key == owner || builtins.elem child.key entryPoints)
        )
      )
    )
    || throw "Catalog import boundary: ${node.key} imports ${child.key}; use a public entry point"
  ) node.imports
) nodes
