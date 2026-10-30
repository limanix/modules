{ lib, theme }:
let
  # The terminal's own colors by number with the system theme; its default colors need no entry.
  colors = lib.mapAttrs (_: toString) (lib.filterAttrs (_: color: color != null) theme.colors);
in
lib.mapAttrsRecursive (_: lib.mkDefault) {
  palette = theme.name;
  palettes.${theme.name} = colors;
  directory.style = "bold blue";
  hostname.style = "bold accent";
  git_branch.style = "bold purple";
  git_status.style = "bold red";
  cmd_duration.style = "bold yellow";
  git_branch.symbol = "";
  hg_branch.symbol = "";
  fossil_branch.symbol = "";
  pijul_channel.symbol = "";
  nodejs.symbol = "node ";
  erlang.symbol = "erlang ";
  azure.symbol = "az ";
  pulumi.symbol = "pulumi ";
  battery = {
    full_symbol = "full ";
    charging_symbol = "charging ";
    discharging_symbol = "discharging ";
    unknown_symbol = "battery ";
    empty_symbol = "empty ";
  };
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
    style = "bold orange";
    format = "([$output]($style) )";
  };
}
