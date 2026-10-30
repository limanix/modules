# Validate the public fields read from a module.toml file.
#
# This checks the module name, description, version lines, default line and prompt shells.
# Unknown fields, reserved names, and invalid values are rejected.
# Version lines are returned in numeric order for the rest of the checks.
# This validation does not load a NixOS configuration or build packages.
name: metadata:
let
  require =
    condition: message: if condition then true else throw "Module catalog: ${name}: ${message}";
  lines = metadata.versions or [ ];
  shells = metadata.prompt.shells or null;
  validLine =
    line:
    builtins.isString line
    && builtins.stringLength line <= 63
    && builtins.match "[0-9]+(\\.[0-9]+)*" line != null;
  numericOrder =
    left: right:
    let
      compared = builtins.compareVersions left right;
    in
    compared < 0 || (compared == 0 && left < right);
in
assert require (
  builtins.isString name
  && builtins.stringLength name <= 63
  && builtins.match "[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*" name != null
) "invalid module name";
assert require (
  !(builtins.elem name [
    "_shared"
    "internal"
    "capabilities"
    "pins"
  ])
) "reserved module name";
assert require (builtins.isAttrs metadata) "metadata must be an attribute set";
assert require (builtins.all (
  field:
  builtins.elem field [
    "description"
    "versions"
    "default"
    "prompt"
  ]
) (builtins.attrNames metadata)) "module.toml contains unknown fields";
assert require (metadata ? description) "description is required";
assert require (builtins.isString metadata.description) "description must be a string";
assert require (
  builtins.match "[[:space:]]*" metadata.description == null
) "description must not be empty";
assert require (builtins.isList lines) "versions must be a list";
assert require (builtins.all validLine lines) "invalid version line";
assert require (
  builtins.length lines == builtins.length (
    builtins.attrNames (
      builtins.listToAttrs (
        map (line: {
          name = line;
          value = true;
        }) lines
      )
    )
  )
) "duplicate version lines";
assert require (
  if lines == [ ] then
    !(metadata ? default)
  else
    metadata ? default && builtins.isString metadata.default && builtins.elem metadata.default lines
) "default must name a declared line and must be absent without lines";
assert require (
  !(metadata ? prompt)
  || (
    builtins.isAttrs metadata.prompt
    && builtins.attrNames metadata.prompt == [ "shells" ]
    && builtins.isList shells
    && shells != [ ]
    && builtins.all (
      shell:
      builtins.elem shell [
        "bash"
        "zsh"
      ]
    ) shells
    &&
      builtins.length shells == builtins.length (
        builtins.attrNames (
          builtins.listToAttrs (
            map (shell: {
              name = shell;
              value = true;
            }) shells
          )
        )
      )
  )
) "prompt must hold only shells, a nonempty list of distinct bash and zsh";
{
  lines = builtins.sort numericOrder lines;
}
// (if lines == [ ] then { } else { inherit (metadata) default; })
// (if metadata ? prompt then { inherit (metadata) prompt; } else { })
