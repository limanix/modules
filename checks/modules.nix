# Generic catalog orchestration. Application policy lives in each public test.nix.
{
  modules ? "[]",
  suite ? "module",
  system ? builtins.currentSystem,
}:
let
  catalog = import ./catalog.nix ../catalog;
  nixpkgs = import ./nixpkgs.nix;
  rawEvaluate =
    selected:
    import ./nixos.nix {
      inherit nixpkgs system;
      modules = selected;
      userName = "module-check";
    };
  base = rawEvaluate [ ];
  inherit (base) pkgs lib;
  require = condition: message: if condition then true else throw "Module checks: ${message}";
  checkScenario =
    evaluated:
    let
      failed = builtins.filter (item: !item.assertion) evaluated.config.assertions;
    in
    assert import ./imports.nix {
      inherit catalog;
      inherit (evaluated) graph;
    };
    if failed != [ ] then
      throw "Module assertions:\n${lib.concatMapStringsSep "\n" (item: item.message) failed}"
    else
      evaluated;
  checkedEvaluate = selected: checkScenario (rawEvaluate selected);

  evalSystem =
    selected:
    let
      singleton = builtins.length selected == 1;
      entry = if singleton then builtins.head selected else null;
      public = singleton && (builtins.isPath entry || builtins.isString entry);
      key = if public then toString entry else "";
    in
    if public && builtins.hasAttr key entryConfigurations then
      entryConfigurations.${key}.config
    else
      (checkedEvaluate selected).config;
  validate = name: import ./test-contract.nix { inherit lib system name; };
  names = map (item: item.name) catalog;
  requested = builtins.fromJSON modules;
  selectedNames = if requested == [ ] then names else lib.unique requested;
  entries = item: [ item.path ] ++ map (line: item.directory + "/versions/${line}.nix") item.lines;

  rawEntries = builtins.listToAttrs (
    lib.concatMap (
      item:
      map (path: {
        name = toString path;
        value = rawEvaluate [ path ];
      }) (entries item)
    ) catalog
  );

  entryConfigurations = builtins.mapAttrs (
    _: evaluated:
    assert import ./ownership.nix {
      inherit lib;
      inherit (evaluated) options;
    };
    checkScenario evaluated
  ) rawEntries;
  entryNames = builtins.listToAttrs (
    lib.concatMap (
      item:
      map (path: {
        name = toString path;
        value = item.name;
      }) (entries item)
    ) catalog
  );
  graphDependencies =
    graph:
    let
      active = builtins.filter (node: !node.disabled);
      nodes = builtins.genericClosure {
        startSet = active graph;
        operator = node: active node.imports;
      };
    in
    lib.unique (
      lib.concatMap (
        node: lib.optional (builtins.hasAttr node.key entryNames) entryNames.${node.key}
      ) nodes
    );
  contexts = builtins.listToAttrs (
    map (item: {
      inherit (item) name;
      value = rec {
        inherit item;
        defaultConfiguration = entryConfigurations.${toString item.path};
        lineConfigurations = builtins.listToAttrs (
          map (line: {
            name = line;
            value = entryConfigurations.${toString (item.directory + "/versions/${line}.nix")};
          }) item.lines
        );
        test = validate item.name (
          import (item.directory + "/test.nix") {
            inherit evalSystem pkgs lib;
          }
        );
        dependencies = builtins.filter (name: name != item.name) (
          lib.unique (
            lib.concatMap (path: graphDependencies rawEntries.${toString path}.graph) (entries item)
          )
        );
        configurations = {
          default = defaultConfiguration;
        }
        // lib.mapAttrs' (line: configuration: {
          name = "line-${line}";
          value = configuration;
        }) lineConfigurations;
        inherit (builtins.fromTOML (builtins.readFile (item.directory + "/module.toml"))) description;
        guide = "https://limanix.dev/categories/nixos/modules/${item.name}/README.html";
        helpCard =
          entry: configuration:
          let
            cards = configuration.config.limanix.help;
            card = cards.${item.name};
          in
          assert require (
            cards ? ${item.name}
          ) "${item.name} (${entry}): every entry point must declare limanix.help.${item.name}";
          assert require (
            card.summary == description
          ) "${item.name}: limanix.help.${item.name}.summary must be the description in module.toml";
          assert require (
            card.guide == guide
          ) "${item.name}: limanix.help.${item.name}.guide must be ${guide}";
          card;
        entryResults = lib.mapAttrs (
          entry: configuration:
          builtins.deepSeq (helpCard entry configuration) configuration.config.system.build.toplevel.drvPath
        ) configurations;

        helpRuns = lib.mapAttrs (
          entry: configuration:
          let
            card = helpCard entry configuration;
            profile = configuration.config.system.path;
          in
          pkgs.runCommand "help-commands-${item.name}-${entry}" { } ''
            for command in ${lib.escapeShellArgs card.commands}; do
              if [ ! -x ${profile}/bin/"$command" ]; then
                echo "${item.name}: the help card names $command, but ${entry} has no such command on PATH" >&2
                exit 1
              fi
            done
            touch "$out"
          ''
        ) configurations;
        recommendations = builtins.listToAttrs (
          map (
            line:
            let
              entry = item.directory + "/versions/${line}.nix";
              selected = lineConfigurations.${line}.config.system.build.toplevel.drvPath;
              first =
                (checkedEvaluate [
                  item.path
                  entry
                ]).config.system.build.toplevel.drvPath;
              last =
                (checkedEvaluate [
                  entry
                  item.path
                ]).config.system.build.toplevel.drvPath;
            in
            {
              name = line;
              value =
                assert require (
                  selected == first && selected == last
                ) "${item.name}: explicit line ${line} must replace the default in both import orders";
                true;
            }
          ) item.lines
        );
      };
    }) catalog
  );
  selectedTests =
    if suite == "module" then
      builtins.listToAttrs (
        map (name: {
          inherit name;
          value = contexts.${name}.test;
        }) selectedNames
      )
    else if suite == "shared" then
      {
        _shared = validate "_shared" (import ../catalog/_shared/test.nix { inherit evalSystem pkgs lib; });
      }
    else
      {
        _platform = validate "_platform" (import ./common.nix { inherit evalSystem pkgs lib; });
      };
  dependencyClosure = builtins.genericClosure {
    startSet = map (name: { key = name; }) selectedNames;
    operator = node: map (name: { key = name; }) contexts.${node.key}.dependencies;
  };
  permissionTests =
    if suite == "module" then
      map (node: contexts.${node.key}.test) dependencyClosure
    else
      builtins.attrValues selectedTests;
  evaluation = lib.mapAttrs (name: test: {
    tests = test.eval;
    entries = if suite == "module" then contexts.${name}.entryResults else { };
    recommendation = if suite == "module" then contexts.${name}.recommendations else { };
  }) selectedTests;
  failureRows = lib.concatMap (
    target: map (key: "${target}\t${key}") (builtins.attrNames selectedTests.${target}.fails)
  ) (builtins.attrNames selectedTests);
  lines = values: lib.concatStringsSep "\n" values + lib.optionalString (values != [ ]) "\n";
  evalManifest = {
    "results.json" = builtins.toJSON evaluation;
    failures = lines failureRows;
    expected = lib.mapAttrs (_: test: lib.mapAttrs (_: value: value.message) test.fails) selectedTests;
  };
  helpRoots =
    group:
    if group == "run" && suite == "module" then
      lib.concatMap (
        name: map (derivation: derivation.drvPath) (builtins.attrValues contexts.${name}.helpRuns)
      ) selectedNames
    else
      [ ];
  runtimeManifest = group: {
    roots = lines (
      lib.unique (
        lib.concatMap (test: map (derivation: derivation.drvPath) (builtins.attrValues test.${group})) (
          builtins.attrValues selectedTests
        )
        ++ helpRoots group
      )
    );
    builds = lines (
      lib.unique (
        lib.concatMap (test: map (value: value.drvPath) (builtins.attrValues test.builds)) (
          if group == "run" then permissionTests else [ ]
        )
      )
    );
  };
  runManifest = runtimeManifest "run";
in
assert require (builtins.elem system [
  "aarch64-linux"
  "x86_64-linux"
]) "a Linux target architecture is required";
assert require (builtins.elem suite [
  "module"
  "shared"
  "platform"
]) "unknown suite";
assert require (
  builtins.isList requested && builtins.all builtins.isString requested
) "modules must be a JSON array of names";
assert require (builtins.all (name: builtins.elem name names) requested) "unknown module name";
assert require (suite == "module" || requested == [ ]) "only the module suite accepts module names";
{
  inherit
    system
    names
    evaluation
    evalManifest
    runManifest
    ;
  selectionManifest.modules = lines selectedNames;
  vmManifest = runtimeManifest "vm";

  checkManifest = {
    eval = evalManifest;
    run = runManifest;
  };
  failure =
    let
      target = builtins.getEnv "LMX_CHECK_TARGET";
      key = builtins.getEnv "LMX_CHECK_CASE";
      failure = selectedTests.${target}.fails.${key};
    in
    builtins.seq (evalSystem failure.modules).system.build.toplevel.drvPath true;
}
