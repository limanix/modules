{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.terraform.versions);
  versions = map (line: config.lmx.internal.terraform.packages.${line}.terraform.version) selected;
in
{
  limanix.help.terraform = {
    title = "Terraform ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [ "terraform" ] ++ map (line: "terraform-${line}") selected;
    tips = [
      {
        label = "Init";
        text = "terraform init";
      }
      {
        label = "Plan";
        text = "terraform plan -out=tfplan";
      }
      {
        label = "Apply";
        text = "terraform apply tfplan";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/terraform/README.html";
  };
}
