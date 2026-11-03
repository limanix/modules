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
    { lmx.capabilities.theme.name = "everforest-dark"; }
  ];
  init = configuration: configuration.config.programs.zsh.promptInit;
  pathColor = configuration: toString configuration.config.lmx.capabilities.theme.colors.blue;
in
{
  eval = {
    defaults = verify "Pure is the Zsh prompt, in the terminal's colors with system" (
      helpers.installed defaultConfiguration pkgs.pure-prompt
      && lib.hasInfix "prompt pure" (init defaultConfiguration)
      && lib.hasInfix "zstyle ':prompt:pure:path' color '4'" (init defaultConfiguration)
      && lib.hasInfix "%F{11}" (init defaultConfiguration)
      && !defaultConfiguration.config.programs.starship.enable
    ) defaultConfiguration;
    theme =
      verify "Pure follows the guest's theme"
        (lib.hasInfix "zstyle ':prompt:pure:path' color '${themed.config.lmx.capabilities.theme.palette.blue}'" (
          init themed
        ))
        themed;
    segment = verify "outside tmux, the right prompt shows the words of lmx status --short" (
      lib.hasInfix "[[ -n $TMUX ]] || words=$(/run/current-system/sw/bin/lmx status --short" (
        init defaultConfiguration
      )
      && lib.hasInfix "RPROMPT='$_lmx_prompt_words'" (init defaultConfiguration)
    ) defaultConfiguration;
  };
  run.startup = import ../../_shared/test/prompt-smoke.nix {
    inherit pkgs;
    name = "pure";
    shell = "zsh";
    init = init themed;
    check = ''
      setopt ERR_EXIT
      [[ $prompt_theme[1] == pure ]]
      [[ ''${+functions[prompt_pure_precmd]} == 1 ]]
      [[ ''${+functions[_lmx_prompt_status]} == 1 ]]
      [[ $RPROMPT == '$_lmx_prompt_words' ]]
      [[ -n ''${COLORTERM:-} ]] || zmodload -e zsh/nearcolor
      zstyle -s ':prompt:pure:path' color path_color
      [[ $path_color == '${pathColor themed}' ]]
    '';
  };
}
