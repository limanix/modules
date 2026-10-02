{
  config,
  lib,
  pkgs,
  ...
}:
let
  shell = "${config.limanix.user.shell}${config.limanix.user.shell.shellPath}";
  window =
    name: command:
    pkgs.writeShellScript "cozy-${name}-window" ''
      cozy_window=${lib.escapeShellArg name}
      cozy_command=${lib.escapeShellArg command}
      cozy_shell=${lib.escapeShellArg shell}
      cozy_fallback_shell=${lib.escapeShellArg "${pkgs.bashInteractive}/bin/bash"}
      ${builtins.readFile ./workspace-tool.sh}
    '';
in
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "tmux-project" ''
      cozy_tmux=${lib.escapeShellArg "${config.programs.tmux.package}/bin/tmux"}
      cozy_editor=${lib.escapeShellArg (toString (window "editor" "${config.programs.neovim.finalPackage}/bin/nvim"))}
      cozy_shell=${lib.escapeShellArg shell}
      cozy_git=${lib.escapeShellArg (toString (window "git" "${config.programs.lazygit.package}/bin/lazygit"))}
      cozy_containers=${lib.escapeShellArg (toString (window "containers" "${pkgs.lazydocker}/bin/lazydocker"))}
      cozy_sha256=${lib.escapeShellArg "${pkgs.coreutils}/bin/sha256sum"}
      ${builtins.readFile ./tmux-project.sh}
    '')
  ];
}
