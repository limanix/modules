# Discover only public module records; private implementation is not inspected.
modulesDir:
let
  require = condition: message: if condition then true else throw "Module catalog: ${message}";
  entries = builtins.readDir modulesDir;
  names = import ./catalog-entries.nix entries;
  sharedFiles =
    if entries._shared or null == "directory" then builtins.readDir (modulesDir + "/_shared") else { };
  catalog = map readModule names;
  readModule =
    name:
    let
      directory = modulesDir + "/${name}";
      files = builtins.readDir directory;
      regular = file: files.${file} or null == "regular";
      metadata = builtins.addErrorContext "while reading ${name}/module.toml" (
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
    ]) "${name}: module.toml, default.nix, test.nix and README.md must be regular files";
    assert require (
      normalized.lines == [ ] || files.versions or null == "directory"
    ) "${name}: versions must be a directory";
    assert require (builtins.all (
      line: versionFiles."${line}.nix" or null == "regular"
    ) normalized.lines) "${name}: every declared line needs a regular versions/<line>.nix";
    assert require (builtins.any (
      line: builtins.isString line && builtins.match "##[[:blank:]]+Guarantees[[:blank:]]*" line != null
    ) (builtins.split "\n" readme)) "${name}: README.md needs a Guarantees section";
    {
      inherit name directory;
      path = directory + "/default.nix";
    }
    // normalized;
in
assert require (
  !(entries ? _shared) || entries._shared == "directory"
) "_shared must be a directory";
assert require (!(sharedFiles ? "module.toml")) "_shared must not have metadata or a selector";
assert require (
  !(entries ? _shared) || sharedFiles."test.nix" or null == "regular"
) "_shared/test.nix must be a regular file";
assert require (names != [ ]) "no modules found";
builtins.deepSeq catalog catalog
