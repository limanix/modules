{
  config,
  pkgs,
  profile,
  profileFor,
  configurations,
  ...
}:
let
  managedProfile = profileFor configurations.managedOverride;
  flavorProfile = profileFor configurations.managedFlavor;
  latteProfile = profileFor configurations.latte;
in
{
  shellErrors =
    pkgs.runCommand "yazi-shell-handoff-errors"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.coreutils
        ];
        LMX_BASH = "${pkgs.bashInteractive}/bin/bash";
        LMX_ZSH = "${pkgs.zsh}/bin/zsh";
        LMX_YAZI_SHELL_INIT = ../shell-init.sh;
        LMX_YAZI_THEME_WRAPPER = ../theme-wrapper.sh;
      }
      ''
        python ${./shell-smoke.py}
        touch "$out"
      '';

  shellHandoff =
    pkgs.runCommand "yazi-theme-and-shell-handoff"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        PYTHONPATH = ../../_shared/test;
        LMX_YAZI_PROFILE = profile;
        LMX_YAZI_MANAGED_PROFILE = managedProfile;
        LMX_YAZI_FLAVOR_PROFILE = flavorProfile;
        LMX_YAZI_LATTE_PROFILE = latteProfile;
        LMX_BASH = "${pkgs.bashInteractive}/bin/bash";
        LMX_ZSH = "${pkgs.zsh}/bin/zsh";
        LMX_BASH_INIT = pkgs.writeText "yazi-bash-init" config.programs.bash.interactiveShellInit;
        LMX_ZSH_INIT = pkgs.writeText "yazi-zsh-init" config.programs.zsh.interactiveShellInit;
        TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
      }
      ''
        python ${./runtime-smoke.py}
        touch "$out"
      '';
}
