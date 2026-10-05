{
  evalSystem,
  pkgs,
  lib,
  moduleDirectory,
  checkLine,
  runLine ? null,
}:
let
  helpers = import ./helpers.nix { inherit evalSystem pkgs lib; };
  metadata = builtins.fromTOML (builtins.readFile (moduleDirectory + "/module.toml"));
  lines = builtins.sort lib.versionOlder (metadata.versions or [ ]);
  entry = line: moduleDirectory + "/versions/${line}.nix";
  configurations = builtins.listToAttrs (
    map (line: {
      name = line;
      value = helpers.evaluate [ (entry line) ];
    }) lines
  );
  defaultConfiguration = helpers.evaluate [ (moduleDirectory + "/default.nix") ];
  allConfiguration = helpers.evaluate (map entry lines);
in
assert lib.assertMsg (builtins.isFunction checkLine)
  "Module line tests: checkLine must be a function";
assert lib.assertMsg (
  runLine == null || builtins.isFunction runLine
) "Module line tests: runLine must be null or a function";
{
  inherit
    metadata
    lines
    configurations
    defaultConfiguration
    allConfiguration
    ;
  eval = builtins.listToAttrs (
    map (line: {
      name = "line-${line}";
      value = helpers.verify "version line ${line}" (checkLine {
        inherit line;
        configuration = configurations.${line};
      }) configurations.${line};
    }) lines
  );
  run =
    if runLine == null then
      { }
    else
      builtins.listToAttrs (
        map (line: {
          name = "commands-${line}";
          value = runLine {
            inherit line;
            configuration = configurations.${line};
          };
        }) lines
      );
}
