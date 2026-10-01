let
  directory = ../catalog/_shared;
  entries = builtins.readDir directory;
  nixFiles =
    root: files:
    builtins.map (name: root + "/${name}") (
      builtins.filter (name: files.${name} == "regular" && builtins.match ".*\\.nix" name != null) (
        builtins.attrNames files
      )
    );
  privateFiles =
    root:
    let
      files = builtins.readDir root;
    in
    nixFiles root files
    ++ builtins.concatMap (name: privateFiles (root + "/${name}")) (
      builtins.filter (name: files.${name} == "directory") (builtins.attrNames files)
    );
in
{
  public = nixFiles directory entries;
  private =
    if entries.internal or null == "directory" then privateFiles (directory + "/internal") else [ ];
}
