{
  evalSystem,
  pkgs,
  lib,
}:
let
  inherit (import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; })
    evaluate
    verify
    installedAsDeclared
    profileFor
    ;
  defaults = evaluate [ ./default.nix ];
  preferred = evaluate [
    ./default.nix
    { programs.neovim.defaultEditor = true; }
  ];
in
{
  eval = {
    defaults = verify "Neovim and its aliases are enabled" (
      defaults.config.programs.neovim.enable
      && defaults.config.programs.neovim.viAlias
      && defaults.config.programs.neovim.vimAlias
      && installedAsDeclared defaults defaults.config.programs.neovim.finalPackage
    ) defaults;
    defaultEditor = verify "the default-editor preference remains overridable" (
      !defaults.config.programs.neovim.defaultEditor
      && preferred.config.programs.neovim.defaultEditor
      && preferred.config.programs.neovim.enable
    ) preferred;
    optionalProviders = verify "plain Neovim declares no optional language tools" (
      defaults.config.lmx.capabilities.languageSupport.tools == { }
      && defaults.config.lmx.capabilities.languageSupport.languages == { }
    ) defaults;
  };
  run.commands = import ./test/smoke.nix {
    inherit pkgs;
    profile = profileFor defaults;
  };
  builds.editor = defaults.config.programs.neovim.finalPackage;
}
