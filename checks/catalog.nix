modulesDir:
let
  entries = builtins.readDir modulesDir;
  names = builtins.filter (name: name != "_shared" || entries.${name} != "directory") (
    builtins.attrNames entries
  );

  require = condition: message: if condition then true else throw "Module catalog: ${message}";
  sharedFiles =
    if entries._shared or null == "directory" then builtins.readDir (modulesDir + "/_shared") else { };

  readModule =
    name:
    assert require (entries.${name} == "directory") "${name} must be a directory";
    assert require (
      !(builtins.elem name [
        "capabilities"
        "internal"
      ])
    ) "reserved module name: ${name}";
    assert require (
      builtins.stringLength name <= 63 && builtins.match "[a-z][a-z0-9]*(-[a-z0-9]+)*" name != null
    ) "invalid module name: ${name}";
    let
      directory = modulesDir + "/${name}";
      files = builtins.readDir directory;
      metadata = builtins.addErrorContext "while reading ${name}/module.toml" (
        builtins.fromTOML (builtins.readFile (directory + "/module.toml"))
      );
      versions = metadata.versions or [ ];
      default = metadata.default or "";
      check = directory + "/check.nix";
      smoke = if files."smoke.nix" or null == "regular" then directory + "/smoke.nix" else null;
      requiredSmokeSources = (import ./smoke-requirements.nix).requiredSources directory;
      readme = builtins.readFile (directory + "/README.md");
      versionFiles = if versions == [ ] then { } else builtins.readDir (directory + "/versions");
      readVersion =
        version:
        assert require (
          builtins.isString version
          && builtins.stringLength version <= 63
          && builtins.match "[0-9]+(\\.[0-9]+)*" version != null
        ) "${name}: invalid version selector";
        assert require (
          versionFiles."${version}.nix" or null == "regular"
        ) "${name}: missing versions/${version}.nix";
        {
          inherit
            check
            directory
            smoke
            version
            ;
          name = "${name}-${version}";
          path = directory + "/versions/${version}.nix";
        };
    in
    assert require (
      files."default.nix" or null == "regular"
    ) "${name}/default.nix must be a regular file";
    assert require (
      files."module.toml" or null == "regular"
    ) "${name}/module.toml must be a regular file";
    assert require (files."check.nix" or null == "regular") "${name}/check.nix must be a regular file";
    assert require (files."README.md" or null == "regular") "${name}/README.md must be a regular file";
    assert require (builtins.any (
      line: builtins.isString line && builtins.match "##[[:blank:]]+Guarantees[[:blank:]]*" line != null
    ) (builtins.split "\n" readme)) "${name}/README.md must contain a Guarantees section";
    assert require (
      !(files ? "smoke.nix") || files."smoke.nix" == "regular"
    ) "${name}/smoke.nix must be a regular file";
    assert require (
      builtins.match ".*`smoke[.]nix`:[[:blank:]].*" readme == null || smoke != null
    ) "${name}: documented smoke.nix checks are missing";
    assert require (requiredSmokeSources == [ ] || smoke != null)
      "${name}: custom builds or program configuration require smoke.nix (${builtins.concatStringsSep ", " (map builtins.baseNameOf requiredSmokeSources)})";
    assert require (builtins.all (
      field:
      builtins.elem field [
        "description"
        "default"
        "versions"
      ]
    ) (builtins.attrNames metadata)) "${name}/module.toml contains unknown fields";
    assert require (metadata ? description) "${name}: description is required";
    assert require (builtins.isString metadata.description) "${name}: description must be a string";
    assert require (
      builtins.match "[[:space:]]*" metadata.description == null
    ) "${name}: description must not be empty";
    assert require (
      builtins.isList versions && builtins.isString default
    ) "${name}: invalid versions or default";
    assert require (builtins.all builtins.isString versions)
      "${name}: version selectors must be strings";
    assert require (
      if versions == [ ] then default == "" else builtins.elem default versions
    ) "${name}: default must select a declared version";
    assert require (
      builtins.length versions == builtins.length (
        builtins.attrNames (
          builtins.listToAttrs (
            map (version: {
              name = version;
              value = true;
            }) versions
          )
        )
      )
    ) "${name}: duplicate versions";
    {
      inherit
        name
        check
        directory
        smoke
        ;
      inherit (metadata) description;
      path = directory + "/default.nix";
      version = if versions == [ ] then null else default;
      variants = builtins.map readVersion versions;
    };

  catalog = builtins.map readModule names;
  selectors = builtins.concatMap (
    module: [ module.name ] ++ builtins.map (variant: variant.name) module.variants
  ) catalog;
  uniqueSelectors = builtins.foldl' (
    seen: selector:
    assert require (!builtins.hasAttr selector seen) "duplicate selector: ${selector}";
    seen // { ${selector} = true; }
  ) { } selectors;
in
assert require (names != [ ]) "no modules found";
assert require (
  !(sharedFiles ? "module.toml")
) "_shared must not have module metadata or a selector";
builtins.seq uniqueSelectors catalog
