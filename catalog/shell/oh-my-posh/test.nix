{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify;
  defaultConfiguration = evaluate [ ./default.nix ];
  themed = evaluate [
    ./default.nix
    { lmx.capabilities.theme.name = "kanagawa-wave"; }
  ];
  bash = configuration: configuration.config.programs.bash.promptInit;
  zsh = configuration: configuration.config.programs.zsh.promptInit;
in
{
  eval.defaults =
    verify
      "Oh My Posh starts in Bash and Zsh with the lmx words and settings made for the guest's theme"
      (
        helpers.installed defaultConfiguration pkgs.oh-my-posh
        && lib.hasInfix "oh-my-posh init bash" (bash defaultConfiguration)
        && lib.hasInfix "oh-my-posh init zsh" (zsh defaultConfiguration)
        && lib.hasInfix "_lmx_status_words" (bash defaultConfiguration)
        && lib.hasInfix "_lmx_status_words" (zsh defaultConfiguration)
        && bash defaultConfiguration != bash themed
      )
      themed;
}
