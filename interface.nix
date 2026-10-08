{ lib, pkgs, ... }:
{
  options.limanix = {
    user = {
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

    session = {
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

    help = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              title = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Heading of the card, such as the tool and its version.";
              };
              summary = lib.mkOption {
                type = lib.types.str;
                description = "One sentence about what the topic gives the guest.";
              };
              commands = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Commands on PATH that the topic provides, most used first.";
              };
              tips = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.submodule {
                    options = {
                      label = lib.mkOption {
                        type = lib.types.strMatching ".{1,10}";
                        description = "Label of the tip, at most 10 characters.";
                      };
                      text = lib.mkOption {
                        type = lib.types.str;
                        description = "A command or a short sentence.";
                      };
                    };
                  }
                );
                default = [ ];
                description = "Common tasks, each a label and a command or sentence.";
              };
              guide = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Address of the full guide.";
              };
            };
          }
        )
      );
      default = { };
      description = "Help cards that `lmx help TOPIC` shows in the guest, by topic.";
    };
  };
}
