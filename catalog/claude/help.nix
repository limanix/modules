let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.claude = {
    title = "Claude Code";
    summary = metadata.description;
    commands = [ "claude" ];
    tips = [
      {
        label = "Sign in";
        text = "Follow the prompts on first launch, or type /login in a session.";
      }
      {
        label = "Continue";
        text = "claude --continue";
      }
      {
        label = "Resume";
        text = "claude --resume";
      }
      {
        label = "Diagnose";
        text = "claude doctor";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/claude/README.html";
  };
}
