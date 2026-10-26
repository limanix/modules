let
  catalog = ../catalog;
  kinds = import ../checks/catalog-kinds.nix;

  read =
    directory:
    let
      file = directory + "/graph.toml";
    in
    if builtins.pathExists file then builtins.fromTOML (builtins.readFile file) else { };

  nodesOf =
    primary: table:
    let
      ids = builtins.attrNames table;
    in
    map (id: table.${id} // { inherit id; }) (
      builtins.filter (id: id == primary) ids ++ builtins.filter (id: id != primary) ids
    );

  modulesOf =
    kind:
    map (name: nodesOf name (read (catalog + "/${kind}/${name}"))) (
      import ../checks/catalog-entries.nix (builtins.readDir (catalog + "/${kind}"))
    );

  nodes =
    nodesOf "theme" (read (catalog + "/_shared"))
    ++ builtins.concatLists (builtins.concatMap modulesOf kinds);

  quote = builtins.toJSON;
  field = name: value: "      ${quote name}: ${value}";

  links =
    node:
    let
      items = node."with" or [ ];
      inline = field "with" "[${builtins.concatStringsSep ", " (map quote items)}]";
      lines = map (item: "        ${quote item}") items;
    in
    if builtins.stringLength inline <= 100 then
      inline
    else
      field "with" "[\n${builtins.concatStringsSep ",\n" lines}\n      ]";

  render =
    node:
    "    {\n"
    + builtins.concatStringsSep ",\n" [
      (field "id" (quote node.id))
      (field "name" (quote node.name))
      (field "text" (quote node.text))
      (links node)
    ]
    + "\n    }";
in
"{\n  \"modules\": [\n${builtins.concatStringsSep ",\n" (map render nodes)}\n  ]\n}\n"
