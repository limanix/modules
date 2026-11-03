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
  themed =
    theme:
    evaluate [
      ../zsh/default.nix
      ./default.nix
      { lmx.capabilities.theme.name = theme; }
    ];
  everforest = themed "everforest-dark";
  mocha = themed "catppuccin-mocha";
  settings = configuration: configuration.config.programs.starship.settings;
in
{
  eval = {
    defaults = verify "Starship starts in Bash and Zsh with the hostname and the exit status" (
      defaultConfiguration.config.programs.starship.enable
      && builtins.elem "starship" defaultConfiguration.config.limanix.help.starship.commands
      && !(settings defaultConfiguration).hostname.ssh_only
      && !(settings defaultConfiguration).status.disabled
      && lib.hasInfix "starship init bash" defaultConfiguration.config.programs.bash.promptInit
      && lib.hasInfix "starship init zsh" defaultConfiguration.config.programs.zsh.promptInit
      && !lib.hasInfix "prompt pure" defaultConfiguration.config.programs.zsh.promptInit
    ) defaultConfiguration;
    theme = verify "Starship follows the guest's theme, and the terminal's colors with system" (
      (settings everforest).palette == "everforest-dark"
      &&
        (settings everforest).palettes.everforest-dark == everforest.config.lmx.capabilities.theme.palette
      && (settings defaultConfiguration).palettes.system.blue == "4"
      && (settings defaultConfiguration).palette == "system"
      && !((settings defaultConfiguration).palettes.system ? foreground)
    ) everforest;
    segment = verify "outside tmux, Starship shows the words of lmx status --short" (
      lib.hasPrefix ''[ -n "$TMUX" ] || '' (settings everforest).custom.lmx.command
      && lib.hasSuffix "lmx status --short" (settings everforest).custom.lmx.command
    ) everforest;
  };
  run.startup = import ../../_shared/test/prompt-smoke.nix {
    inherit pkgs;
    name = "starship";
    shell = "zsh";
    init = mocha.config.programs.zsh.promptInit;
    path = [ mocha.config.programs.starship.package ];
    check = ''
      setopt ERR_EXIT
      [[ $STARSHIP_CONFIG == /nix/store/* ]]
      starship print-config | grep -F 'ssh_only = false'
      starship print-config | grep -F 'palette = "catppuccin-mocha"'
      starship module directory | grep -F '38;2;137;180;250'
      [[ -n $(starship module hostname) ]]
      starship module status --status 7 | grep -F 7
      [[ -z $(starship module status --status 0) ]]
    '';
  };
}
