# Pure validation of the public module.toml ABI.
name: metadata:
let
  require =
    condition: message: if condition then true else throw "Module catalog: ${name}: ${message}";
  lines = metadata.versions or [ ];
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
{
  lines = builtins.sort numericOrder lines;
}
// (if lines == [ ] then { } else { inherit (metadata) default; })
