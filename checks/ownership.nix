# Validate declaration ownership, including nested public option schemas.
{ lib, options }:
let
  catalogPrefix = toString ../catalog + "/";
  interfaceFile = toString ../interface.nix;
  platformFile = toString ../catalog/_shared/test/platform.nix;
  startsWith = prefix: path: lib.take (builtins.length prefix) path == prefix;
  owns =
    file: path:
    let
      source = toString file;
      relative = lib.removePrefix catalogPrefix source;
      owner = builtins.head (lib.splitString "/" relative);
      publicArea = builtins.match "_shared/([^/]+)\\.nix" relative;
      catalogNamespace = startsWith [ "limanix" ] path || startsWith [ "lmx" ] path;
    in
    if source == "lib/modules.nix" then
      true
    else if source == interfaceFile then
      startsWith [ "limanix" ] path
    else if source == platformFile then
      path == [
        "environment"
        "systemPackages"
      ]
    else if lib.hasPrefix catalogPrefix source then
      if relative == "_shared/pins.nix" then
        startsWith [ "lmx" "pins" ] path
      else if publicArea != null && relative != "_shared/test.nix" then
        startsWith [ "lmx" "capabilities" (builtins.head publicArea) ] path
      else
        !(builtins.elem owner [
          "_shared"
          "internal"
          "capabilities"
          "pins"
        ])
        && (startsWith [ "lmx" owner ] path || startsWith [ "lmx" "internal" owner ] path)
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
