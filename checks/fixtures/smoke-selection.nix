{
  pkgs,
  lib,
  selector,
  includeShared,
  allVersionsConfiguration,
  configurations,
  config,
  ...
}:
{
  commands =
    assert
      !(configurations ? selectedPath) || configurations.selectedPath == (config.fixturePath or null);
    pkgs.runCommand "contract-commands-${selector}" { } "touch $out";
}
// lib.optionalAttrs includeShared {
  coexistence = builtins.seq allVersionsConfiguration (
    pkgs.runCommand "contract-coexistence" { } "touch $out"
  );
  configuration = builtins.seq (configurations.providerOverride or null) (
    pkgs.runCommand "contract-configuration" { } "touch $out"
  );
}
