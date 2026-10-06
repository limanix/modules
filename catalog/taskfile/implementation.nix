version:
{
  pkgs,
  lib,
  pinned,
  ...
}:
let
  releases = import ./releases.nix;
  source = releases.sources.${releases.versions.${version}.source};
  tools = import ./packages.nix {
    inherit version pinned;
  };

  releaseValues = builtins.attrValues releases.versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.task.version
  ) releaseValues;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  versionedTask = pkgs.runCommandLocal "task-${version}-command" { } ''
    mkdir -p "$out/bin"
    ln -s "${tools.task}/bin/task" "$out/bin/task-${version}"
  '';
in
{
  lmx.pins.${source.rev} = source.sha256;
  lmx.internal.taskfile.packages.${version} = tools;

  environment.systemPackages = [
    (lib.setPrio priority tools.task)
    versionedTask
  ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Task ${tools.task.version} no longer receives upstream security updates.";
}
