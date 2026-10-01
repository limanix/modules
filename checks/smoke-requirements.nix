let
  # Recognize the builders and custom program configuration used by the catalog.
  # This is a regression check for these forms, not an interpreter for arbitrary Nix.
  builders = "(runCommand(Local|CC)?|mkDerivation|buildVimPlugin|symlinkJoin|linkFarm|buildEnv|write(ShellScript(Bin)?|Script(Bin)?|Text(File|Dir)?))";
  startupOptions = "(customLuaRC|interactiveShellInit|loginShellInit|shellInit|initExtra|extraConfigBeforePlugins|extraConfig|preStart|postStart|preStop|postStop|preReload|postReload)";
  stripComments =
    source:
    builtins.concatStringsSep "" (
      builtins.filter builtins.isString (builtins.split "(#[^\n]*|/[*]([^*]|[*]+[^*/])*[*]+/)" source)
    );
  sourceNeedsSmoke =
    source:
    let
      code = stripComments source;
      matches = pattern: builtins.match ".*${pattern}.*" code != null;
    in
    matches "(^|[^[:alnum:]_'-])${builders}[[:space:]]+[\"({[:alnum:]_]"
    || matches "(^|[^[:alnum:]_'-])${startupOptions}[[:space:]]*="
    || matches "programs[[:space:]]*[.][[:space:]]*git[[:space:]]*[.][[:space:]]*config[[:space:]]*=";
  sourceFiles =
    directory:
    let
      entries = builtins.readDir directory;
      isTest =
        name:
        builtins.elem name [
          "check.nix"
          "smoke.nix"
          "test.nix"
        ]
        || builtins.match "(.*-(check|smoke|test)|(check|smoke|test)-.*)[.]nix" name != null;
    in
    builtins.concatMap (
      name:
      let
        path = directory + "/${name}";
      in
      if entries.${name} == "directory" then
        if
          builtins.elem name [
            "checks"
            "tests"
            "fixtures"
          ]
        then
          [ ]
        else
          sourceFiles path
      else if entries.${name} == "regular" && builtins.match ".*[.]nix" name != null && !isTest name then
        [ path ]
      else
        [ ]
    ) (builtins.attrNames entries);
in
{
  inherit sourceNeedsSmoke sourceFiles;
  requiredSources =
    directory:
    builtins.filter (path: sourceNeedsSmoke (builtins.readFile path)) (sourceFiles directory);
}
