{
  profile,
  profileFor,
  pkgs,
  version,
  tools,
  newestTools,
  allVersionsConfiguration,
  includeShared,
  ...
}:
{
  commands = pkgs.runCommand "task-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$(readlink -f ${profile}/bin/task-${version})" = "$(readlink -f ${tools.task}/bin/task)"
    ${profile}/bin/task-${version} --version | grep -F '${tools.task.version}'
    mkdir "$TMPDIR/project"
    cp ${./fixtures/Taskfile.yml} "$TMPDIR/project/Taskfile.yml"
    ${profile}/bin/task-${version} --dir "$TMPDIR/project" --list | grep -F 'Read the generated file'
    ${profile}/bin/task-${version} --dir "$TMPDIR/project" default OUTPUT="$TMPDIR/generated" > "$TMPDIR/output"
    grep -Fx 'prepared' "$TMPDIR/output"
    grep -Fx 'message=module-ok' "$TMPDIR/output"
    touch "$out"
  '';
}
// pkgs.lib.optionalAttrs includeShared {
  coexistence = import ../../_shared/test/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    expectedCommands = {
      task = "${newestTools.task}/bin/task";
      go-task = "${newestTools.task}/bin/go-task";
    };
  };
}
