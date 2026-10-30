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
  themed = evaluate [
    module.path
    { lmx.capabilities.theme.name = "nord"; }
  ];
  inherit (themed.config.lmx.capabilities.theme) palette;
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
    theme = verify "styles follow the guest's theme, and the terminal's colors with system" (
      lib.hasInfix "set -g status-style 'bg=${palette.background_dark},fg=${palette.foreground}'" (
        text themed
      )
      && lib.hasInfix "set -g status-style 'bg=default,fg=default'" (text defaultConfiguration)
      && lib.hasInfix "set -g pane-active-border-style 'fg=magenta'" (text defaultConfiguration)
      && !lib.hasInfix "#" (
        lib.concatStrings (
          builtins.filter (line: lib.hasInfix "-style" line) (
            lib.splitString "\n" (text defaultConfiguration)
          )
        )
      )
    ) themed;
    segment =
      verify "the status line shows the words of lmx status --short"
        (lib.hasInfix "#[fg=${palette.orange},bold]#(/run/current-system/sw/bin/lmx status --short)" (
          text themed
        ))
        themed;
  };
}
