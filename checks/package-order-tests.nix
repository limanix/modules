{ nixpkgs, system }:
let
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;
  weak = lib.setPrio 20 (pkgs.writeShellScriptBin "limanix-order-fixture" "printf weak");
  strong = lib.setPrio 4 (pkgs.writeShellScriptBin "limanix-order-fixture" "printf strong");
  contributions = [
    {
      environment.systemPackages = lib.mkBefore [
        weak
        weak
      ];
    }
    { environment.systemPackages = lib.mkAfter [ strong ]; }
  ];
  evaluate =
    modules:
    import ./nixos.nix {
      inherit nixpkgs system modules;
      userName = "profile-check";
    };
  original = evaluate contributions;
  reversed = evaluate (lib.reverseList contributions);
  packages =
    candidate:
    builtins.filter (
      package: package.outPath == weak.outPath || package.outPath == strong.outPath
    ) candidate.config.environment.systemPackages;
  priority =
    package:
    if builtins.isAttrs package then
      package.meta.priority or lib.meta.defaultPriority
    else
      lib.meta.defaultPriority;
  wrapped = {
    __toString = _: toString weak;
    meta.priority = 9;
  };
  userPackages = [
    "${weak}"
    wrapped
    (lib.setPrio 7 strong)
    strong
  ];
  userForms = evaluate [ { environment.systemPackages = userPackages; } ];
  forced = evaluate (contributions ++ [ { environment.systemPackages = lib.mkForce userPackages; } ]);
  userSelection =
    candidate:
    builtins.filter (
      package: toString package == weak.outPath || toString package == strong.outPath
    ) candidate.config.environment.systemPackages;
  selected = packages original;
  priorities = map (package: package.meta.priority) selected;
  profile = pkgs.buildEnv {
    name = "contract-profile-order";
    paths = selected;
    pathsToLink = [ "/bin" ];
  };
in
{
  evaluation =
    assert builtins.length selected == 3;
    assert builtins.length (userSelection userForms) == 4;
    assert builtins.any builtins.isString (userSelection userForms);
    assert builtins.any (
      package: builtins.isAttrs package && !(package ? outPath) && package ? __toString
    ) (userSelection userForms);
    assert
      builtins.sort builtins.lessThan (map priority (userSelection userForms)) == [
        4
        5
        7
        9
      ];
    assert builtins.length forced.config.environment.systemPackages == 4;
    assert
      map (package: {
        path = toString package;
        rank = priority package;
      }) (userSelection forced) == map (package: {
        path = toString package;
        rank = priority package;
      }) (userSelection userForms);
    assert builtins.length (builtins.filter (package: package.outPath == weak.outPath) selected) == 2;
    assert builtins.length (builtins.filter (package: package.outPath == strong.outPath) selected) == 1;
    assert
      builtins.sort builtins.lessThan priorities == [
        4
        20
        20
      ];
    assert
      map (package: {
        path = package.outPath;
        priority = package.meta.priority;
      }) selected == map (package: {
        path = package.outPath;
        priority = package.meta.priority;
      }) (packages reversed);
    assert
      original.config.system.build.toplevel.drvPath == reversed.config.system.build.toplevel.drvPath;
    true;
  smoke = pkgs.runCommand "contract-profile-order-smoke" { } ''
    test "$(${profile}/bin/limanix-order-fixture)" = strong
    test "$(readlink -f ${profile}/bin/limanix-order-fixture)" = "${strong}/bin/limanix-order-fixture"
    touch "$out"
  '';
}
