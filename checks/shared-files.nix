# Only root NixOS schemas are autoloaded; shared test.nix is a reserved export.
let
  directory = ../catalog/_shared;
  entries = builtins.readDir directory;
in
{
  public = map (name: directory + "/${name}") (
    builtins.filter (
      name: name != "test.nix" && entries.${name} == "regular" && builtins.match ".*\\.nix" name != null
    ) (builtins.attrNames entries)
  );
}
