{ lib, theme }:
lib.mapAttrsRecursive (_: lib.mkDefault) {
  palette = "catppuccin_${theme.flavor}";
  palettes."catppuccin_${theme.flavor}" = theme.palette;
  directory.style = "bold blue";
  hostname.style = "bold lavender";
  git_branch.style = "bold mauve";
  git_status.style = "bold red";
  cmd_duration.style = "bold yellow";
  character = {
    success_symbol = "[❯](bold green)";
    error_symbol = "[❯](bold red)";
    vimcmd_symbol = "[❮](bold green)";
  };
  # The words of lmx status --short that need attention, such as restart. Inside tmux its status
  # line shows them, so the prompt does not ask.
  custom.lmx = {
    description = "What the guest owner needs attention for";
    command = ''[ -n "$TMUX" ] || exec /run/current-system/sw/bin/lmx status --short'';
    when = true;
    shell = [ "sh" ];
    style = "bold peach";
    format = "([$output]($style) )";
  };
}
