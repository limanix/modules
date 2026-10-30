{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./help.nix ];

  environment.systemPackages = [ pkgs.pure-prompt ];

  programs.zsh.promptInit = lib.mkDefault (
    import ./init.nix {
      inherit lib;
      inherit (config.lmx.capabilities) theme;
      pure = pkgs.pure-prompt;
    }
  );
}
