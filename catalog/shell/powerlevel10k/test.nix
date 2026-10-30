{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate verify;
  defaultConfiguration = evaluate [
    ../zsh/default.nix
    ./default.nix
  ];
  themed = evaluate [
    ../zsh/default.nix
    ./default.nix
    { lmx.capabilities.theme.name = "tokyo-night"; }
  ];
  init = configuration: configuration.config.programs.zsh.promptInit;
in
{
  eval.defaults = verify "Powerlevel10k is the Zsh prompt, with a style made for the guest's theme" (
    lib.hasInfix "/share/zsh-powerlevel10k/powerlevel10k.zsh-theme" (init defaultConfiguration)
    && lib.hasInfix "powerlevel10k-limanix.zsh" (init defaultConfiguration)
    && init defaultConfiguration != init themed
    && !defaultConfiguration.config.programs.starship.enable
  ) themed;
}
