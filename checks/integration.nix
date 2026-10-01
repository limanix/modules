let
  system = builtins.currentSystem;
  nixpkgs = import ./nixpkgs.nix;
  catalog = import ./catalog.nix ../catalog;
  userName = "module-check";
  evaluate =
    modules:
    import ./nixos.nix {
      inherit
        nixpkgs
        system
        userName
        modules
        ;
    };
  empty = evaluate [ ];
  inherit (empty) pkgs lib;
  entry = name: builtins.head (builtins.filter (module: module.name == name) catalog);
  checkResult =
    configuration: selected:
    import selected.check {
      inherit (configuration) config pkgs;
      inherit (selected) version;
      inherit userName;
      hasPackage = package: installed configuration package;
    };
  installed =
    configuration: package:
    builtins.any (
      candidate: candidate.outPath == package.outPath
    ) configuration.config.environment.systemPackages;
  result =
    configuration:
    assert import ./ownership.nix { inherit (configuration) lib options; };
    configuration.config.system.build.toplevel.drvPath;
  verify =
    label: valid: configuration:
    builtins.trace "Checking ${system}: integration: ${label}" (
      if valid then result configuration else throw "Catalog integration: ${label}"
    );
  capability = configuration: configuration.config.lmx.capabilities.languageSupport;
  combined = evaluate (map (module: module.path) catalog);
  console = entry "console";
  consoleConfiguration = evaluate [ console.path ];
  consoleShell = evaluate [
    console.path
    { limanix.user.shell = pkgs.bashInteractive; }
  ];
  consoleNavigation = evaluate [
    console.path
    { lmx.tmux.navigation.enable = false; }
  ];
  originalText = consoleConfiguration.config.environment.etc."tmux.conf".text;
  disabledText = consoleNavigation.config.environment.etc."tmux.conf".text;
  bindings =
    lib.concatMap
      (key: [
        "bind -n C-${key} "
        "bind -n M-${key} "
        "bind C-${key} send-keys "
      ])
      [
        "h"
        "j"
        "k"
        "l"
      ];
  astronvim = entry "astronvim";
  selectedAstro = builtins.head (
    builtins.filter (variant: variant.version == astronvim.version) astronvim.variants
  );
  astroStandalone = evaluate [ selectedAstro.path ];
  astroWithDefault = evaluate [
    astronvim.path
    selectedAstro.path
  ];
  astroWithConsole = evaluate [
    console.path
    selectedAstro.path
  ];
  astroReversed = evaluate [
    selectedAstro.path
    console.path
  ];
  minikube = entry "minikube";
  k9s = entry "k9s";
  selectedK9s = builtins.head k9s.variants;
  newestK9s = builtins.head (builtins.filter (variant: variant.version == k9s.version) k9s.variants);
  explicitK9s = evaluate [
    minikube.path
    selectedK9s.path
  ];
  multipleK9s = evaluate [
    minikube.path
    selectedK9s.path
    newestK9s.path
  ];
  k9sWithDefault = evaluate [
    minikube.path
    selectedK9s.path
    k9s.path
  ];
  k9sPackages = version: import ../catalog/k9s/packages.nix { inherit system version; };
  recommendedK9s = (k9sPackages k9s.version).k9s;
  explicitK9sPackage = (k9sPackages selectedK9s.version).k9s;
  installedK9s =
    configuration:
    builtins.filter (
      candidate: (candidate.pname or null) == "k9s"
    ) configuration.config.environment.systemPackages;
  hasOnlyK9s =
    configuration: expected:
    let
      packages = installedK9s configuration;
    in
    builtins.length packages == builtins.length expected
    && builtins.all (
      package:
      builtins.length (builtins.filter (candidate: candidate.outPath == package.outPath) packages) == 1
    ) expected;
  priority =
    package:
    (builtins.head (
      builtins.filter (candidate: candidate.outPath == package.outPath) (installedK9s multipleK9s)
    )).meta.priority;
  suppliedGopls = pkgs.writeShellScriptBin "gopls" ''
    test "$#" -ge 1 && test "$1" = --catalog-smoke || exit 64
    shift
    exec ${pkgs.gopls}/bin/gopls "$@"
  '';
  suppliedTool = {
    package = suppliedGopls;
    command = "${suppliedGopls}/bin/gopls";
    args = [ "--catalog-smoke" ];
    languages = [ "go" ];
  };
  thirdParty = {
    environment.systemPackages = [
      pkgs.go
      suppliedGopls
    ];
    lmx.capabilities.languageSupport = {
      tools.gopls = suppliedTool;
      languages.go.parsers = [ "go" ];
    };
  };
  thirdPartyConfiguration = evaluate [ thirdParty ];
  thirdPartyConsumer = evaluate [
    astronvim.path
    thirdParty
  ];
  userOverrideConsumer = evaluate [
    astronvim.path
    (entry "go").path
    { lmx.capabilities.languageSupport.tools.gopls = suppliedTool; }
  ];
  parserOnly = evaluate [
    { lmx.capabilities.languageSupport.languages.example.parsers = [ "lua" ]; }
  ];
  providers = [
    (entry "go")
    (entry "rust")
  ];
  providerConsumer = evaluate ([ astronvim.path ] ++ map (module: module.path) providers);
  evaluation = {
    combined =
      verify "all compatible module defaults" (builtins.all (checkResult combined) catalog)
        combined;
    emptyCapabilities = verify "empty selection exposes capabilities without consumers" (
      (capability empty).tools == { }
      && (capability empty).languages == { }
      && !empty.config.programs.neovim.enable
      && !empty.config.programs.tmux.enable
      && !empty.config.programs.zsh.enable
    ) empty;
    parserOnly = verify "parser-only language adds no package or consumer" (
      (capability parserOnly).tools == { }
      && (capability parserOnly).languages.example.parsers == [ "lua" ]
      && !parserOnly.config.programs.neovim.enable
      && parserOnly.config.environment.systemPackages == empty.config.environment.systemPackages
    ) parserOnly;
    console = {
      shell = verify "Console accepts a Bash login-shell override" (
        consoleShell.config.limanix.user.shell == pkgs.bashInteractive
        && consoleShell.config.users.users.${userName}.shell == pkgs.bashInteractive
        && consoleShell.config.programs.zsh.enable
      ) consoleShell;
      navigation = verify "Console disables navigation while retaining tmux features" (
        !consoleNavigation.config.lmx.tmux.navigation.enable
        && consoleNavigation.config.programs.tmux.enable
        && consoleNavigation.config.programs.tmux.keyMode == "vi"
        &&
          consoleNavigation.config.programs.tmux.plugins == consoleConfiguration.config.programs.tmux.plugins
        && builtins.all (
          binding: lib.hasInfix binding originalText && !lib.hasInfix binding disabledText
        ) bindings
        && lib.hasInfix "set -g mouse on" disabledText
      ) consoleNavigation;
      astronvimVersionSelection =
        verify "explicit AstroNvim line overrides recommendation and import order"
          (
            checkResult astroStandalone selectedAstro
            && checkResult astroWithConsole selectedAstro
            && checkResult astroReversed selectedAstro
            && result astroStandalone == result astroWithDefault
            &&
              astroWithConsole.config.programs.neovim.finalPackage.drvPath
              == astroReversed.config.programs.neovim.finalPackage.drvPath
            && builtins.deepSeq (result astroReversed) true
          )
          astroWithConsole;
    };
    minikubeK9sSelection = verify "Minikube accepts explicit and coexisting K9s lines" (
      checkResult explicitK9s minikube
      && checkResult explicitK9s selectedK9s
      && checkResult multipleK9s minikube
      && checkResult multipleK9s selectedK9s
      && checkResult multipleK9s newestK9s
      && hasOnlyK9s explicitK9s [ explicitK9sPackage ]
      && hasOnlyK9s k9sWithDefault [ explicitK9sPackage ]
      && hasOnlyK9s multipleK9s [
        explicitK9sPackage
        recommendedK9s
      ]
      && priority recommendedK9s < priority explicitK9sPackage
      && builtins.deepSeq (result explicitK9s) true
    ) multipleK9s;
    thirdPartyCapabilities = verify "third-party provider needs no catalog application imports" (
      (capability thirdPartyConfiguration).tools.gopls.package.outPath == suppliedGopls.outPath
      && (capability thirdPartyConfiguration).tools.gopls.command == suppliedTool.command
      && (capability thirdPartyConfiguration).tools.gopls.args == suppliedTool.args
      && (capability thirdPartyConfiguration).languages.go.parsers == [ "go" ]
      && installed thirdPartyConfiguration suppliedGopls
      && !thirdPartyConfiguration.config.programs.neovim.enable
    ) thirdPartyConfiguration;
    thirdPartyConsumer = verify "AstroNvim accepts the final third-party gopls declaration" (
      thirdPartyConsumer.config.programs.neovim.enable
      &&
        builtins.toJSON (capability thirdPartyConsumer).tools
        == builtins.toJSON (capability thirdPartyConfiguration).tools
      && installed thirdPartyConsumer suppliedGopls
    ) thirdPartyConsumer;
    providerConsumer = verify "AstroNvim and optional Go/Rust providers compose" (
      checkResult providerConsumer astronvim
      && builtins.all (checkResult providerConsumer) providers
      &&
        builtins.all
          (identity: installed providerConsumer (capability providerConsumer).tools.${identity}.package)
          [
            "gopls"
            "rust-analyzer"
          ]
    ) providerConsumer;
  };
  runtime = import ../catalog/astronvim/integration.nix {
    inherit pkgs;
    inherit (astroStandalone) config;
    configurations = { inherit providerConsumer thirdPartyConsumer userOverrideConsumer; };
  };
  smoke = map (
    name:
    let
      check = runtime.${name};
    in
    assert lib.isDerivation check || throw "Integration smoke: ${name} must be a derivation";
    assert check.system == system || throw "Integration smoke: ${name} must target ${system}";
    builtins.trace "Smoke integration.astronvim.${name}: ${check.drvPath}" check
  ) (builtins.attrNames runtime);
in
assert
  builtins.elem system [
    "aarch64-linux"
    "x86_64-linux"
  ]
  || throw "Integration checks require a native Linux runner";
builtins.deepSeq catalog {
  inherit system evaluation smoke;
}
