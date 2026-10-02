{ lib }:
lib.mapAttrsRecursive (_: lib.mkDefault) {
  palette = "catppuccin_mocha";
  palettes.catppuccin_mocha = (builtins.fromTOML (builtins.readFile ../_shared/palette.toml)).mocha;
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
}
