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
    { lmx.capabilities.theme.name = "rose-pine"; }
  ];
  bash = configuration: configuration.config.programs.bash.promptInit;
  zsh = configuration: configuration.config.programs.zsh.promptInit;
in
{
  eval.defaults =
    verify
      "Liquidprompt starts in Bash and Zsh, in the terminal's colors with system and the palette otherwise"
      (
        lib.hasInfix "/bin/liquidprompt" (bash defaultConfiguration)
        && lib.hasInfix "/bin/liquidprompt" (zsh defaultConfiguration)
        && lib.hasInfix "lmx status --short" (bash defaultConfiguration)
        && !(defaultConfiguration.config.environment.etc ? liquidpromptrc)
        && themed.config.environment.etc.liquidpromptrc.enable
      )
      themed;
}
