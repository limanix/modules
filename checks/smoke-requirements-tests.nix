let
  requirements = import ./smoke-requirements.nix;
  custom = import ./catalog.nix ./fixtures/smoke-required;
  packages = import ./catalog.nix ./fixtures/smoke-package-only;
  recognizes = requirements.sourceNeedsSmoke;
in
assert !(builtins.tryEval (builtins.deepSeq custom true)).success;
assert builtins.deepSeq packages (builtins.length packages == 1);
assert requirements.requiredSources ./fixtures/smoke-package-only/example == [ ];
assert recognizes
  ''{ pkgs, ... }: { environment.systemPackages = [ (pkgs.runCommand "example" {} "touch $out") ]; }'';
assert recognizes ''stdenvNoCC.mkDerivation { name = "example"; }'';
assert recognizes ''pkgs.vimUtils.buildVimPlugin { name = "example"; }'';
assert recognizes ''pkgs.symlinkJoin { name = "example"; paths = []; }'';
assert recognizes ''pkgs.writeShellScript "example" "echo example"'';
assert recognizes ''{ programs.neovim.configure.customLuaRC = "print('example')"; }'';
assert recognizes ''{ programs.zsh.interactiveShellInit = "example"; }'';
assert recognizes ''{ programs.tmux.extraConfigBeforePlugins = "set -g mouse on"; }'';
assert recognizes ''{ programs.git.config = { core.pager = "delta"; }; }'';
assert !(recognizes "{ pkgs, ... }: { environment.systemPackages = [ pkgs.hello ]; }");
assert
  !(recognizes ''
    # pkgs.runCommand "example" {} "touch $out"
      { programs.git.enable = true; }
  '');
assert
  !(recognizes ''
    /* pkgs.runCommand "example" {} "touch $out" */
      { programs.git.enable = true; }
  '');
true
