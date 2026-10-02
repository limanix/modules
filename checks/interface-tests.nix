{
  nixpkgs,
  system,
}:
let
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;
  evaluate =
    modules:
    lib.evalModules {
      specialArgs = { inherit pkgs; };
      modules = [ ../interface.nix ] ++ modules;
    };
  defaults = evaluate [ ];
  provider = "${pkgs.coreutils}/bin/true";
  alternative = "${pkgs.coreutils}/bin/false";
  recommended = {
    limanix.session.command = lib.mkDefault provider;
  };
  selected = evaluate [
    recommended
    { limanix.session.command = alternative; }
  ];
  reversed = evaluate [
    { limanix.session.command = alternative; }
    recommended
  ];
  disabled = evaluate [
    recommended
    { limanix.session.command = null; }
  ];
  shellOverride = evaluate [ { limanix.user.shell = pkgs.zsh; } ];
  noSuggestions = evaluate [ { limanix.session.providers = [ ]; } ];
  conflicts = evaluate [
    recommended
    { limanix.session.command = lib.mkDefault alternative; }
  ];
  invalidPath = evaluate [ { limanix.session.command = "relative-command"; } ];
  invalidShell = evaluate [ { limanix.user.shell = "bash"; } ];
  rejects = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
in
{
  evaluation =
    assert defaults.config.limanix.user.shell == pkgs.bashInteractive;
    assert defaults.config.limanix.session.command == null;
    assert builtins.isList defaults.config.limanix.session.providers;
    assert selected.config.limanix.session.command == alternative;
    assert reversed.config.limanix.session.command == alternative;
    assert disabled.config.limanix.session.command == null;
    assert shellOverride.config.limanix.user.shell == pkgs.zsh;
    assert noSuggestions.config.limanix.session.providers == [ ];
    assert rejects invalidPath.config.limanix.session.command;
    assert rejects invalidShell.config.limanix.user.shell;
    assert defaults.options.limanix.user.name.readOnly;
    assert defaults.options.limanix.user.home.readOnly;
    assert !(defaults.options.limanix.user.name ? default);
    assert !(defaults.options.limanix.user.home ? default);
    true;
  diagnostics.sessionProviders = {
    expected = "limanix.session.command' has conflicting definition values";
    actual = conflicts.config.limanix.session.command;
  };
}
