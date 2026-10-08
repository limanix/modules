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
    ];
    guide = "https://limanix.dev/categories/nixos/modules/cli-tools/README.html";
  };
}
