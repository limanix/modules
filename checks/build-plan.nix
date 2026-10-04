# Validate exact dry-run permissions. Never grant a derivation's dependencies.
{
  planned,
  roots,
  builds,
  derivations,
}:
let
  require = condition: message: if condition then true else throw "Build plan: ${message}";
  isPath =
    value:
    builtins.isString value
    && builtins.match "/nix/store/[a-z0-9]{32}-[^/[:space:]]+[.]drv" value != null;
  records =
    if derivations ? derivations then
      assert require (builtins.elem (derivations.version or null) [
        3
        4
      ]) "unsupported derivation JSON version";
      builtins.listToAttrs (
        map (name: {
          name = "/nix/store/${name}";
          value = derivations.derivations.${name};
        }) (builtins.attrNames derivations.derivations)
      )
    else
      derivations;
  localBuild =
    value:
    if value ? structuredAttrs && value.structuredAttrs ? preferLocalBuild then
      builtins.isBool value.structuredAttrs.preferLocalBuild && value.structuredAttrs.preferLocalBuild
    else
      (value.env.preferLocalBuild or "") == "1";
  permitted =
    path:
    assert require (builtins.hasAttr path records) "missing metadata for ${path}";
    builtins.elem path roots || builtins.elem path builds || localBuild records.${path};
  blocked = builtins.filter (path: !permitted path) planned;
in
assert require (builtins.all (values: builtins.isList values && builtins.all isPath values) [
  planned
  roots
  builds
]) "expected lists of store derivation paths";
assert require (
  builtins.isAttrs derivations && builtins.isAttrs records
) "invalid derivation metadata";
{
  inherit planned blocked;
  allowed = blocked == [ ];
}
