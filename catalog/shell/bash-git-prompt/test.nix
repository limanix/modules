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
    { lmx.capabilities.theme.name = "nord"; }
  ];
  init = configuration: configuration.config.programs.bash.promptInit;
in
{
  eval.defaults =
    verify "bash-git-prompt starts in Bash with the lmx words and colors made for the guest's theme"
      (
        lib.hasInfix "/gitprompt.sh" (init defaultConfiguration)
        && lib.hasInfix "GIT_PROMPT_FETCH_REMOTE_STATUS-0" (init defaultConfiguration)
        && lib.hasInfix "lmx status --short" (init defaultConfiguration)
        && init defaultConfiguration != init themed
      )
      themed;
}
