{
  module,
  defaultConfiguration,
  evaluate,
  lib,
  verify,
  ...
}:
let
  navigationDisabled = evaluate [
    module.path
    { lmx.tmux.navigation.enable = false; }
  ];
  preferencesOverride = evaluate [
    module.path
    {
      programs.tmux = {
        keyMode = "emacs";
        terminal = "screen-256color";
        escapeTime = 25;
        extraConfig = ''
          set -g status-style 'bg=black,fg=white'
          set -g pane-active-border-style 'fg=blue'
          set -g mode-style 'bg=blue,fg=white'
        '';
      };
    }
  ];
  latte = evaluate [
    module.path
    { lmx.capabilities.theme.flavor = "latte"; }
  ];
  inherit (latte.config.lmx.capabilities.theme) palette;
  text = configuration: configuration.config.environment.etc."tmux.conf".text;
  bindings =
    lib.concatMap
      (key: [
        "bind -n C-${key} "
        "bind -n M-${key} "
        "bind C-${key} send-keys "
      ])
      [
        "h"
        "j"
        "k"
        "l"
      ];
in
{
  configurations = { inherit navigationDisabled preferencesOverride; };
  evaluation = {
    preferences = verify "defaults and ordinary preference overrides" (
      defaultConfiguration.config.programs.tmux.keyMode == "vi"
      && defaultConfiguration.config.programs.tmux.terminal == "tmux-256color"
      && defaultConfiguration.config.programs.tmux.escapeTime == 10
      && preferencesOverride.config.programs.tmux.keyMode == "emacs"
      && preferencesOverride.config.programs.tmux.terminal == "screen-256color"
      && preferencesOverride.config.programs.tmux.escapeTime == 25
    ) preferencesOverride;
    navigation = verify "navigation switch preserves the other tmux features" (
      defaultConfiguration.config.lmx.tmux.navigation.enable
      && !navigationDisabled.config.lmx.tmux.navigation.enable
      && navigationDisabled.config.programs.tmux.enable
      && navigationDisabled.config.programs.tmux.keyMode == "vi"
      &&
        navigationDisabled.config.programs.tmux.plugins == defaultConfiguration.config.programs.tmux.plugins
      && builtins.all (
        binding:
        lib.hasInfix binding (text defaultConfiguration) && !lib.hasInfix binding (text navigationDisabled)
      ) bindings
      && lib.hasInfix "set -g mouse on" (text navigationDisabled)
      && lib.hasInfix "set -s set-clipboard on" (text navigationDisabled)
    ) navigationDisabled;
    theme =
      verify "styles follow the guest's flavor"
        (lib.hasInfix "set -g status-style 'bg=${palette.mantle},fg=${palette.text}'" (text latte))
        latte;
    segment =
      verify "the status line shows the words of lmx status --short"
        (lib.hasInfix "#[fg=${palette.peach},bold]#(/run/current-system/sw/bin/lmx status --short)" (
          text latte
        ))
        latte;
  };
}
