{
  system,
  selectors,
}:
let
  checks = import ./smoke.nix { inherit system; };
  selected = builtins.fromJSON selectors;
in
builtins.concatMap (
  selector:
  builtins.map (
    name:
    let
      check = checks.${selector}.${name};
      label = "${selector}.${name}";
    in
    builtins.addErrorContext "while instantiating catalog smoke ${label}" (
      builtins.trace "Smoke ${label}: ${check.drvPath}" check
    )
  ) (builtins.attrNames checks.${selector})
) selected
