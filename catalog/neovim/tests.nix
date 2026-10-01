{
  module,
  defaultConfiguration,
  evaluate,
  verify,
  ...
}:
let
  overridden = evaluate [
    module.path
    { programs.neovim.defaultEditor = true; }
  ];
in
{
  evaluation.defaultEditor = verify "default editor setting and ordinary override" (
    !defaultConfiguration.config.programs.neovim.defaultEditor
    && overridden.config.programs.neovim.defaultEditor
  ) overridden;
}
