{ pkgs, ... }:
{
  commands =
    pkgs.runCommand "cloud-tools-offline-commands"
      {
        nativeBuildInputs = [
          pkgs.awscli2
          pkgs.google-cloud-sdk
        ];
      }
      ''
        export HOME="$TMPDIR/home"
        export CLOUDSDK_CONFIG="$HOME/.config/gcloud"
        export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true
        export CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK=true
        mkdir -p "$HOME"
        aws --version > aws-version.txt 2>&1
        grep -F 'aws-cli/2.' aws-version.txt
        gcloud version > gcloud-version.txt 2>&1
        grep -F 'Google Cloud SDK' gcloud-version.txt
        touch "$out"
      '';
}
