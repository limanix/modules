# List the public schemas at the root of catalog/_shared.
#
# Only regular .nix files are included; the reserved test.nix is excluded.
# Files in lib/ and test/ are not public schemas.
# Shared declaration checks use this list to choose files and validate imports.
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
