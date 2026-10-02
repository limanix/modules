{
  variants,
  evaluate,
  defaultVersionEntryPoint,
  componentChecks,
  ...
}:
let
  conflicting = evaluate (
    map (variant: variant.path) [
      (builtins.elemAt variants 0)
      (builtins.elemAt variants 1)
    ]
  );
in
{
  evaluation = {
    defaultEntryPoint = defaultVersionEntryPoint;
    composition = componentChecks;
  };
  diagnostics.versionConflict = {
    expected = "defined multiple times while it's expected to be unique";
    actual =
      assert builtins.length variants >= 2 || throw "Docker conflict check needs two declared versions";
      conflicting.config.virtualisation.docker.package.outPath;
  };
}
