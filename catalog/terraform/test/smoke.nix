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
  commands = pkgs.runCommand "terraform-${version}-commands-smoke" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    export CHECKPOINT_DISABLE=1
    export TF_IN_AUTOMATION=1
    test "$(readlink -f ${profile}/bin/terraform-${version})" = "$(readlink -f ${tools.terraform}/bin/terraform)"
    ${profile}/bin/terraform-${version} version | grep -F '${tools.terraform.version}'
    mkdir "$TMPDIR/project"
    cat > "$TMPDIR/project/main.tf" <<'HCL'
    terraform { required_version = "= ${tools.terraform.version}" }
    output "answer" { value = 41 + 1 }
    HCL
    ${profile}/bin/terraform-${version} -chdir="$TMPDIR/project" init -backend=false -input=false
    ${profile}/bin/terraform-${version} -chdir="$TMPDIR/project" validate -no-color
    ${profile}/bin/terraform-${version} -chdir="$TMPDIR/project" plan -refresh=false -input=false -no-color -out="$TMPDIR/plan"
    ${profile}/bin/terraform-${version} -chdir="$TMPDIR/project" show -json "$TMPDIR/plan" > "$TMPDIR/plan.json"
    ${pkgs.jq}/bin/jq -e '.planned_values.outputs.answer.value == 42' "$TMPDIR/plan.json"
    touch "$out"
  '';
}
// pkgs.lib.optionalAttrs includeShared {
  coexistence = import ../../_shared/test/profile-commands.nix {
    inherit pkgs;
    profile = profileFor allVersionsConfiguration;
    expectedCommands = {
      terraform = "${newestTools.terraform}/bin/terraform";
    };
  };
}
