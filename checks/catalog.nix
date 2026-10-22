# Discover only public module records and release maps; private implementation is not inspected.
# A module lives below its kind, catalog/<kind>/<name>. Its name stays unique across the kinds: the
# name owns the option namespace lmx.<name>, the help topic and the documentation address.
modulesDir:
let
  require = condition: message: if condition then true else throw "Module catalog: ${message}";
  kinds = import ./catalog-kinds.nix;
  entries = builtins.readDir modulesDir;
  unexpected = builtins.filter (
    name: name != "_shared" && !(builtins.elem name kinds) && entries.${name} != "regular"
  ) (builtins.attrNames entries);
  sharedFiles =
    if entries._shared or null == "directory" then builtins.readDir (modulesDir + "/_shared") else { };
  namesOf =
    kind:
    if entries ? ${kind} then
      import ./catalog-entries.nix (builtins.readDir (modulesDir + "/${kind}"))
    else
      [ ];
  catalog = builtins.concatMap (kind: map (readModule kind) (namesOf kind)) kinds;
  names = map (module: module.name) catalog;
  distinct = builtins.attrNames (
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = null;
      }) names
    )
  );
  readModule =
    kind: name:
    let
      label = "${kind}/${name}";
      directory = modulesDir + "/${label}";
      files = builtins.readDir directory;
      regular = file: files.${file} or null == "regular";
      metadata = builtins.addErrorContext "while reading ${label}/module.toml" (
        builtins.fromTOML (builtins.readFile (directory + "/module.toml"))
      );
      normalized = import ./catalog-metadata.nix name metadata;
      versionFiles = if normalized.lines == [ ] then { } else builtins.readDir (directory + "/versions");
      readme = builtins.readFile (directory + "/README.md");
    in
    assert require (builtins.all regular [
      "module.toml"
      "default.nix"
      "test.nix"
      "README.md"
    ]) "${label}: module.toml, default.nix, test.nix and README.md must be regular files";
    assert require (
      normalized.lines == [ ] || files.versions or null == "directory"
    ) "${label}: versions must be a directory";
    assert require (builtins.all (
      line: versionFiles."${line}.nix" or null == "regular"
    ) normalized.lines) "${label}: every declared line needs a regular versions/<line>.nix";
    assert require (builtins.any (
      line: builtins.isString line && builtins.match "##[[:blank:]]+Guarantees[[:blank:]]*" line != null
    ) (builtins.split "\n" readme)) "${label}: README.md needs a Guarantees section";
    assert
      !(regular "releases.nix")
      || import ./catalog-releases.nix name normalized.lines (import (directory + "/releases.nix"));
    {
      inherit name kind directory;
      path = directory + "/default.nix";
    }
    // normalized;
in
assert require (unexpected == [ ])
  "${builtins.concatStringsSep ", " unexpected}: a module lives below its kind, one of ${builtins.concatStringsSep ", " kinds}";
assert require (builtins.all (
  kind: entries.${kind} or "directory" == "directory"
) kinds) "every kind must be a directory";
assert require (
  !(entries ? _shared) || entries._shared == "directory"
) "_shared must be a directory";
assert require (!(sharedFiles ? "module.toml")) "_shared must not have metadata or a selector";
assert require (
  !(entries ? _shared) || sharedFiles."test.nix" or null == "regular"
) "_shared/test.nix must be a regular file";
assert require (
  builtins.length distinct == builtins.length names
) "a module name must be unique across kinds";
assert require (names != [ ]) "no modules found";
builtins.deepSeq catalog catalog
