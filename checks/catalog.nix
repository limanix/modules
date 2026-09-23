modulesDir:
let
  entries = builtins.readDir modulesDir;
  names = builtins.attrNames entries;

  require = condition: message: if condition then true else throw "Module catalog: ${message}";

  readModule =
    name:
    assert require (entries.${name} == "directory") "${name} must be a directory";
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
      inherit name;
      inherit (metadata) description;
      path = directory + "/default.nix";
      variants = builtins.map readVersion versions;
    };
in
assert require (names != [ ]) "no modules found";
builtins.map readModule names
