{ pkgs, profile }:
{
  commands =
    pkgs.runCommand "aws-offline-commands"
      {
        nativeBuildInputs = [ profile ];
      }
      ''
        export HOME="$TMPDIR/home" AWS_EC2_METADATA_DISABLED=true
        mkdir -p "$HOME"
        aws --version > version.txt 2>&1
        grep -F 'aws-cli/2.' version.txt
        touch "$out"
      '';
}
