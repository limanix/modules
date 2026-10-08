let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.codex = {
    title = "Codex CLI";
    summary = metadata.description;
    commands = [ "codex" ];
    tips = [
      {
        label = "Sign in";
        text = "codex login --device-auth";
      }
      {
        label = "Status";
        text = "codex login status";
      }
      {
        label = "Resume";
        text = "codex resume";
      }
      {
        label = "Run once";
        text = "codex exec \"TASK\"";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/codex/README.html";
  };
}
