{ lib, pkgs, ... }:
{
  options.limanix.user = {
    name = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Development account name supplied by LimaNix.";
    };
    home = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Development account home supplied by LimaNix.";
    };
    shell = lib.mkOption {
      type = lib.types.shellPackage;
      default = pkgs.bashInteractive;
      defaultText = lib.literalExpression "pkgs.bashInteractive";
      description = "Login shell for the development account.";
    };
  };

  options.limanix.session = {
    command = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Absolute executable path of the session provider; receives one literal nonempty session name.";
    };
    providers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "lmx:tmux" ];
      description = "Catalog selectors suggested when no session provider is configured.";
    };
  };
}
