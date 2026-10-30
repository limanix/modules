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
    { lmx.capabilities.theme.name = "dracula"; }
  ];
  init = configuration: configuration.config.programs.zsh.promptInit;
in
{
  eval.defaults = verify "Spaceship is the Zsh prompt, with settings made for the guest's theme" (
    lib.hasInfix "/lib/spaceship-prompt/spaceship.zsh" (init defaultConfiguration)
    && lib.hasInfix "spaceship-limanix.zsh" (init defaultConfiguration)
    && init defaultConfiguration != init themed
  ) themed;
}
