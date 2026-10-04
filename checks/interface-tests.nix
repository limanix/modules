{
  evalSystem,
  pkgs,
  lib,
}:
let
  declarations = lib.evalModules {
    specialArgs = { inherit pkgs; };
    modules = [ ../interface.nix ];
  };
  defaults = evalSystem [ ];
  custom = evalSystem [
    {
      limanix.user.shell = pkgs.zsh;
      programs.zsh.enable = true;
      limanix.session.command = "${pkgs.coreutils}/bin/true";
    }
  ];
  force = field: { config, ... }: {
    assertions = [
      {
        assertion = builtins.seq (lib.getAttrFromPath field config) true;
        message = "Interface test: force ${lib.showOption field}";
      }
    ];
  };
in
{
  eval = {
    publicInterface =
      defaults.limanix.user.shell.outPath == pkgs.bashInteractive.outPath
      && defaults.limanix.session.command == null
      && builtins.isList defaults.limanix.session.providers;
    identityDeclaration =
      declarations.options.limanix.user.name.readOnly
      && declarations.options.limanix.user.home.readOnly
      && !(declarations.options.limanix.user.name ? default)
      && !(declarations.options.limanix.user.home ? default);
    platformIdentity =
      defaults.users.users.${defaults.limanix.user.name}.home == defaults.limanix.user.home
      &&
        defaults.users.users.${defaults.limanix.user.name}.shell.outPath
        == defaults.limanix.user.shell.outPath
      && defaults.users.users.${defaults.limanix.user.name}.uid == 1000
      && custom.limanix.user.name == defaults.limanix.user.name
      && custom.limanix.user.home == defaults.limanix.user.home
      && custom.users.users.${defaults.limanix.user.name}.home == defaults.limanix.user.home
      && custom.users.users.${defaults.limanix.user.name}.shell.outPath == pkgs.zsh.outPath
      && custom.limanix.session.command == "${pkgs.coreutils}/bin/true";
  };
  fails = {
    relativeSessionCommand = {
      modules = [
        { limanix.session.command = "relative-command"; }
        (force [
          "limanix"
          "session"
          "command"
        ])
      ];
      message = "limanix.session.command";
    };
    invalidShell = {
      modules = [
        { limanix.user.shell = "bash"; }
        (force [
          "limanix"
          "user"
          "shell"
        ])
      ];
      message = "limanix.user.shell";
    };
  };
}
