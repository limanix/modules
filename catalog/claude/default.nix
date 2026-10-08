{ pkgs, ... }:
{
  imports = [ ./help.nix ];

  nixpkgs.config.allowUnfreePackages = [ "claude-code" ];
  environment.systemPackages = [ pkgs.claude-code ];
  # The catalog pins the version: keep claude update and claude install from
  # placing a separate self-updating copy under ~/.local.
  environment.sessionVariables.DISABLE_UPDATES = "1";
}
