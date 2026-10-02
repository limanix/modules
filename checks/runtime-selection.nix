{
  profile ? "all",
  versions ? [ ],
  modules,
}:
let
  require = condition: message: if condition then true else throw "Module runtime: ${message}";
  unique = builtins.foldl' (
    seen: version: if builtins.elem version seen then seen else seen ++ [ version ]
  ) [ ] versions;
  known =
    if builtins.length modules == 1 then
      map (variant: variant.version) (builtins.head modules).variants
    else
      [ ];
in
assert require (builtins.elem profile [
  "all"
  "pr"
]) "profile must be all or pr";
assert require (
  builtins.isList versions && builtins.all builtins.isString versions
) "versions must be an array of strings";
assert require (versions == [ ] || profile == "pr") "version requests require the pr profile";
assert require (builtins.length versions == builtins.length unique) "duplicate version request";
assert require (
  versions == [ ] || builtins.length modules == 1
) "version requests require exactly one selected module";
assert require (builtins.all (
  version: builtins.elem version known
) versions) "unknown version requested for selected module";
{
  inherit profile versions;
}
