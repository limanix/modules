{
  evalSystem,
  pkgs,
  lib,
}:
let
  configuredUser = {
    name = "configured-user";
    home = "/home/configured user";
    shell = pkgs.bashInteractive;
  };
  fixture = (import ./platform.nix { userName = "default-user"; }) {
    inherit lib;
    config = {
      limanix.user = configuredUser;
      system.nixos.release = "fixture-release";
    };
  };
  canonical = fixture.options.environment.systemPackages.apply;
  priority = (import ./helpers.nix { inherit evalSystem pkgs lib; }).packagePriority;
  weak = lib.setPrio 20 (pkgs.writeShellScriptBin "shared-priority-fixture" "printf weak");
  strong = lib.setPrio 4 (pkgs.writeShellScriptBin "shared-priority-fixture" "printf strong");
  wrapped = {
    __toString = _: toString weak;
    meta.priority = 9;
    marker = "keep";
  };
  values = [
    weak
    weak
    strong
    "${weak}"
    wrapped
    (lib.setPrio 7 weak)
  ];
  describe =
    packages:
    map (package: {
      path = toString package;
      rank = priority package;
    }) packages;
  sorted = canonical values;
  configuration = evalSystem [
    {
      environment.systemPackages = lib.mkBefore [
        weak
        weak
      ];
    }
    { environment.systemPackages = lib.mkAfter [ strong ]; }
  ];
  selected = builtins.filter (
    package: toString package == toString weak || toString package == toString strong
  ) configuration.environment.systemPackages;
  forced = evalSystem [
    {
      environment.systemPackages = [
        weak
        strong
      ];
    }
    {
      environment.systemPackages = lib.mkForce [
        wrapped
        "${weak}"
      ];
    }
  ];
  profile = pkgs.buildEnv {
    name = "shared-canonical-package-profile";
    paths = selected;
    pathsToLink = [ "/bin" ];
  };
in
{
  eval = {
    vmPlatform =
      fixture.config.users.users.${configuredUser.name}.home == configuredUser.home
      && fixture.config.users.users.${configuredUser.name}.shell == configuredUser.shell
      && fixture.config.users.users.${configuredUser.name}.uid == 1000
      && fixture.config.system.stateVersion == "fixture-release"
      && builtins.elem ../languageSupport.nix fixture.imports
      && builtins.elem ../pins.nix fixture.imports
      && !(builtins.elem ../test.nix fixture.imports);
    canonicalPackages =
      describe sorted == describe (canonical (lib.reverseList values))
      && describe selected == describe (canonical selected);
    packageValues =
      builtins.length sorted == builtins.length values
      && builtins.length (builtins.filter (package: toString package == toString weak) sorted) == 5
      && builtins.any (
        package: builtins.isString package && builtins.getContext package == builtins.getContext "${weak}"
      ) sorted
      && builtins.any (
        package: builtins.isAttrs package && (package.marker or null) == "keep" && priority package == 9
      ) sorted
      &&
        builtins.sort builtins.lessThan (map priority sorted) == [
          4
          5
          7
          9
          20
          20
        ]
      && builtins.length forced.environment.systemPackages == 2
      &&
        describe forced.environment.systemPackages == describe (canonical [
          wrapped
          "${weak}"
        ]);
  };
  run.packagePriority = pkgs.runCommand "shared-canonical-package-priority" { } ''
    test "$(${profile}/bin/shared-priority-fixture)" = strong
    test "$(readlink -f ${profile}/bin/shared-priority-fixture)" = "${strong}/bin/shared-priority-fixture"
    touch "$out"
  '';
}
