let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.gh = {
    title = "GitHub CLI";
    summary = metadata.description;
    commands = [ "gh" ];
    tips = [
      {
        label = "Sign in";
        text = "gh auth login";
      }
      {
        label = "Open a PR";
        text = "gh pr create --fill";
      }
      {
        label = "Review";
        text = "gh pr checkout NUMBER";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/gh/README.html";
  };
}
