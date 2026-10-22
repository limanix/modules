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
  starshipLatte = withPrompt "starship" { lmx.capabilities.theme.flavor = "latte"; };
  pureLatte = withPrompt "pure" { lmx.capabilities.theme.flavor = "latte"; };
  none = withPrompt "none" { };
  promptOverride = evaluate [
    module.path
    { programs.zsh.promptInit = "PROMPT='> '"; }
  ];
  inherit (starshipLatte.config.programs.starship) settings;
  preferencesOverride = evaluate [
    module.path
    {
      lmx.zsh.prompt = "starship";
      programs = {
        starship.settings = {
          palette = "custom";
          palettes.custom.blue = "#123456";
          directory.style = "bold cyan";
          hostname.ssh_only = true;
          status.disabled = true;
        };
        atuin.settings = {
          auto_sync = true;
          update_check = true;
        };
      };
    }
  ];
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
      && !none.config.programs.starship.enable
      && lib.strings.trim (pureInit none) == ""
      && !(builtins.elem "starship" (commands none))
    ) none;
    promptOverride = verify "an ordinary promptInit assignment replaces the managed prompt" (
      lib.strings.trim (pureInit promptOverride) == "PROMPT='> '"
      && !promptOverride.config.programs.starship.enable
    ) promptOverride;
    preferences = verify "Starship and history preferences support ordinary overrides" (
      !starship.config.programs.starship.settings.hostname.ssh_only
      && starship.config.programs.starship.settings.palette == "system"
      && !starship.config.programs.starship.settings.status.disabled
      && preferencesOverride.config.programs.starship.settings.palette == "custom"
      && preferencesOverride.config.programs.starship.settings.directory.style == "bold cyan"
      && !defaultConfiguration.config.programs.atuin.settings.auto_sync
      && !defaultConfiguration.config.programs.atuin.settings.update_check
      && preferencesOverride.config.programs.starship.settings.hostname.ssh_only
      && preferencesOverride.config.programs.starship.settings.status.disabled
      && preferencesOverride.config.programs.atuin.settings.auto_sync
      && preferencesOverride.config.programs.atuin.settings.update_check
    ) preferencesOverride;
    theme =
      verify "Pure and Starship follow the guest's flavor, and the terminal's colors with system"
        (
          settings.palette == "catppuccin_latte"
          && settings.palettes.catppuccin_latte == starshipLatte.config.lmx.capabilities.theme.palette
          && lib.hasInfix "zstyle ':prompt:pure:path' color '${pureLatte.config.lmx.capabilities.theme.palette.blue}'" (
            pureInit pureLatte
          )
          && lib.hasInfix "zstyle ':prompt:pure:path' color '4'" (pureInit defaultConfiguration)
          && lib.hasInfix "%F{11}" (pureInit defaultConfiguration)
          && starship.config.programs.starship.settings.palettes.system.blue == "4"
          && !(starship.config.programs.starship.settings.palettes.system ? text)
        )
        pureLatte;
    segment = verify "outside tmux, Pure and Starship show the words of lmx status --short" (
      lib.hasPrefix ''[ -n "$TMUX" ] || '' settings.custom.lmx.command
      && lib.hasSuffix "lmx status --short" settings.custom.lmx.command
      && lib.hasInfix "[[ -n $TMUX ]] || words=$(/run/current-system/sw/bin/lmx status --short" (
        pureInit defaultConfiguration
      )
      && lib.hasInfix "RPROMPT='$_lmx_prompt_words'" (pureInit defaultConfiguration)
    ) starshipLatte;
  };
}
