{ pkgs, profile }:
{
  commands =
    pkgs.runCommand "gcloud-offline-commands"
      {
        nativeBuildInputs = [ profile ];
      }
      ''
        export HOME="$TMPDIR/home" CLOUDSDK_CONFIG="$TMPDIR/config"
        export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true
        export CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK=true
        mkdir -p "$HOME" "$CLOUDSDK_CONFIG"
        gcloud version > version.txt 2>&1
        grep -F 'Google Cloud SDK' version.txt
        gke-gcloud-auth-plugin --version > plugin.txt 2>&1
        grep -F 'Kubernetes v' plugin.txt
        touch "$out"
      '';
}
