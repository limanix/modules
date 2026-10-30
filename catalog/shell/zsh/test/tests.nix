{
  module,
  defaultConfiguration,
  evaluate,
  lib,
  pkgs,
  userName,
  verify,
  ...
}:
let
  withPrompt =
    prompt: extra:
    evaluate [
      module.path
      ({ lmx.zsh.prompt = prompt; } // extra)
    ];
  shellOverride = evaluate [
    module.path
    { limanix.user.shell = pkgs.bashInteractive; }
  ];
  starship = withPrompt "starship" { };
  starshipThemed = withPrompt "starship" { lmx.capabilities.theme.name = "everforest-dark"; };
  pureThemed = withPrompt "pure" { lmx.capabilities.theme.name = "everforest-dark"; };
  none = withPrompt "none" { };
  inherit (starshipThemed.config.programs.starship) settings;
  commands = configuration: configuration.config.limanix.help.zsh.commands;
  pureInit = configuration: configuration.config.programs.zsh.promptInit;
in
{
  evaluation = {
    shell = verify "suggested account shell and ordinary Bash override" (
      defaultConfiguration.config.limanix.user.shell == pkgs.zsh
      && shellOverride.config.limanix.user.shell == pkgs.bashInteractive
      && shellOverride.config.users.users.${userName}.shell == pkgs.bashInteractive
      && shellOverride.config.programs.zsh.enable
    ) shellOverride;
    prompts = verify "each prompt choice installs only its prompt and names its commands" (
      !(builtins.elem "starship" (commands defaultConfiguration))
      && starship.config.programs.starship.enable
      && !lib.hasInfix "prompt pure" (pureInit starship)
      && builtins.elem "starship" (commands starship)
      && !starship.config.programs.starship.settings.hostname.ssh_only
      && !starship.config.programs.starship.settings.status.disabled
      && !none.config.programs.starship.enable
      && lib.strings.trim (pureInit none) == ""
      && !(builtins.elem "starship" (commands none))
    ) none;
    theme = verify "Pure and Starship follow the guest's theme, and the terminal's colors with system" (
      settings.palette == "everforest-dark"
      && settings.palettes.everforest-dark == starshipThemed.config.lmx.capabilities.theme.palette
      && lib.hasInfix "zstyle ':prompt:pure:path' color '${pureThemed.config.lmx.capabilities.theme.palette.blue}'" (
        pureInit pureThemed
      )
      && lib.hasInfix "zstyle ':prompt:pure:path' color '4'" (pureInit defaultConfiguration)
      && lib.hasInfix "%F{11}" (pureInit defaultConfiguration)
      && starship.config.programs.starship.settings.palettes.system.blue == "4"
      && starship.config.programs.starship.settings.palette == "system"
      && !(starship.config.programs.starship.settings.palettes.system ? foreground)
    ) pureThemed;
    segment = verify "outside tmux, Pure and Starship show the words of lmx status --short" (
      lib.hasPrefix ''[ -n "$TMUX" ] || '' settings.custom.lmx.command
      && lib.hasSuffix "lmx status --short" settings.custom.lmx.command
      && lib.hasInfix "[[ -n $TMUX ]] || words=$(/run/current-system/sw/bin/lmx status --short" (
        pureInit defaultConfiguration
      )
      && lib.hasInfix "RPROMPT='$_lmx_prompt_words'" (pureInit defaultConfiguration)
    ) starshipThemed;
  };
}
