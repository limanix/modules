let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.cli-tools = {
    title = "CLI tools";
    summary = metadata.description;
    commands = [
      "rg"
      "fd"
      "fzf"
      "bat"
      "jq"
      "yq"
      "xh"
      "btop"
      "git"
    ];
    tips = [
      {
        label = "Pick file";
        text = "fd --type f | fzf";
      }
      {
        label = "Examples";
        text = "tldr --update && tldr tar";
      }
      {
        label = "Git diffs";
        text = "git diff and git log -p show changes through delta.";
      }
      {
        label = "Identity";
        text = "git config --global user.name \"Your Name\"";
      }
    ];
    guide = "https://docs.limanix.dev/modules/cli-tools";
  };
}
