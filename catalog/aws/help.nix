let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.aws = {
    title = "AWS CLI";
    summary = metadata.description;
    commands = [ "aws" ];
    tips = [
      {
        label = "Set up";
        text = "aws configure sso --use-device-code";
      }
      {
        label = "Sign in";
        text = "aws sso login --use-device-code --profile NAME";
      }
      {
        label = "Account";
        text = "aws sts get-caller-identity --profile NAME";
      }
      {
        label = "Settings";
        text = "aws configure list --profile NAME";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/aws/README.html";
  };
}
