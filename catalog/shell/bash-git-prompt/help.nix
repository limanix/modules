let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.bash-git-prompt = {
    title = "bash-git-prompt";
    summary = metadata.description;
    tips = [
      {
        label = "Colors";
        text = "~/.git-prompt-colors.sh replaces the managed colors; git_prompt_make_custom_theme starts one.";
      }
      {
        label = "Themes";
        text = "git_prompt_list_themes lists the themes that ship with it.";
      }
    ];
    guide = "https://docs.limanix.dev/modules/bash-git-prompt";
  };
}
