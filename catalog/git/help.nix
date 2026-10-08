let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.git = {
    title = "Git";
    summary = metadata.description;
    commands = [ "git" ];
    tips = [
      {
        label = "Your name";
        text = "git config --global user.name \"Your Name\"";
      }
      {
        label = "Your email";
        text = "git config --global user.email \"you@example.com\"";
      }
      {
        label = "One repo";
        text = "Use --local instead of --global inside a repository.";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/git/README.html";
  };
}
