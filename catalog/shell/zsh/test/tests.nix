{
  module,
  defaultConfiguration,
  evaluate,
  pkgs,
  userName,
  verify,
  ...
}:
let
  shellOverride = evaluate [
    module.path
    { limanix.user.shell = pkgs.bashInteractive; }
  ];
in
{
  evaluation = {
    shell = verify "suggested account shell and ordinary Bash override" (
      defaultConfiguration.config.limanix.user.shell == pkgs.zsh
      && shellOverride.config.limanix.user.shell == pkgs.bashInteractive
      && shellOverride.config.users.users.${userName}.shell == pkgs.bashInteractive
      && shellOverride.config.programs.zsh.enable
    ) shellOverride;
  };
}
