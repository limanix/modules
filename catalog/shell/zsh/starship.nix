{ lib, theme }:
let
  system = theme.flavor == "system";
  # The terminal's own colors by number with the system flavor; its default colors need no entry.
  name = if system then "system" else "catppuccin_${theme.flavor}";
  colors =
    if system then
      lib.mapAttrs (_: toString) (lib.filterAttrs (_: color: color != null) theme.ansi)
    else
      theme.palette;
in
lib.mapAttrsRecursive (_: lib.mkDefault) {
  palette = name;
  palettes.${name} = colors;
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
  custom.lmx = {
    description = "What the guest owner needs attention for";
    command = ''[ -n "$TMUX" ] || exec /run/current-system/sw/bin/lmx status --short'';
    when = true;
    shell = [ "sh" ];
    style = "bold peach";
    format = "([$output]($style) )";
  };
}
