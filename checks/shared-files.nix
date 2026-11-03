# Public shared schemas are regular root-level .nix files except test.nix.
# Files in lib/ and test/ remain private.
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
