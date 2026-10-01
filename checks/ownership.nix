{
  lib,
  options,
}:
let
  catalogPrefix = toString ../catalog + "/";
  interfaceFile = toString ../interface.nix;
  startsWith = prefix: path: lib.take (builtins.length prefix) path == prefix;
  owns =
    file: path:
    let
      source = toString file;
      relative = lib.removePrefix catalogPrefix source;
      parts = lib.splitString "/" relative;
      module = builtins.head parts;
      publicArea = builtins.match "_shared/([^/]+)\\.nix" relative;
      catalogNamespace = startsWith [ "limanix" ] path || startsWith [ "lmx" ] path;
    in
    if source == "lib/modules.nix" then
      true
    else if source == interfaceFile then
      startsWith [ "limanix" ] path
    else if lib.hasPrefix catalogPrefix source then
      if publicArea != null then
        startsWith [ "lmx" "capabilities" (builtins.head publicArea) ] path
      else if lib.hasPrefix "_shared/internal/" relative then
        startsWith [ "lmx" "internal" ] path
      else
        module != "_shared" && (startsWith [ "lmx" module ] path || startsWith [ "lmx" "internal" ] path)
    else
      !catalogNamespace;
  checkTree =
    ancestors: prefix: tree:
    builtins.all (
      name:
      let
        option = tree.${name};
        path = option.loc or (prefix ++ [ name ]);
        signature = {
          inherit name;
          declarations = option.declarations or [ ];
          type = option.type.name or null;
        };
        catalogOption =
          startsWith [ "limanix" ] path
          || startsWith [ "lmx" ] path
          || builtins.any (
            file: toString file == interfaceFile || lib.hasPrefix catalogPrefix (toString file)
          ) (option.declarations or [ ]);
      in
      if lib.isOption option then
        builtins.all (
          file:
          owns file path
          || throw "Catalog declaration owner: ${lib.showOption path} is declared by ${toString file}"
        ) option.declarations
        && (
          # Recurse through catalog-owned schemas, including nested option types.
          # Framework-only types can embed the complete NixOS option tree again.
          !catalogOption
          || builtins.elem signature ancestors
          || checkTree (ancestors ++ [ signature ]) path (option.type.getSubOptions path)
        )
      else if builtins.isAttrs option then
        checkTree ancestors (prefix ++ [ name ]) option
      else
        true
    ) (builtins.attrNames tree);
in
checkTree [ ] [ ] options
