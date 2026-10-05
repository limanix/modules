# Pure ABI regressions; fixtures do not instantiate or build Nix derivations.
{ lib, system }:
let
  validate = import ./test-contract.nix {
    inherit lib system;
    name = "fixture";
  };
  base = {
    eval.promise = true;
  };
  fixture = {
    type = "derivation";
    inherit system;
    drvPath = "/nix/store/fixture-test.drv";
    marker = "original";
    passthru = {
      recursive = fixture;
      unforced = throw "ABI validator forced derivation passthru";
    };
  };
  foreign = fixture // {
    system = "foreign-system";
  };
  forceEval = test: builtins.deepSeq (validate test).eval true;
  forceFails =
    test:
    let
      values = (validate test).fails;
    in
    builtins.all (key: builtins.seq values.${key}.modules (builtins.seq values.${key}.message true)) (
      builtins.attrNames values
    );
  forceDerivations =
    group: test:
    let
      values = (validate test).${group};
    in
    builtins.all (key: builtins.seq values.${key}.drvPath true) (builtins.attrNames values);
  rejects = force: test: !(builtins.tryEval (force test)).success;
  complete = validate (
    base
    // {
      fails.expected = {
        modules = [
          (throw "ABI validator forced a module")
          (value: value)
        ];
        message = "Expected diagnostic";
      };
      run.commands = fixture;
      builds.application = fixture;
      vm.activation = fixture;
    }
  );
  validFailure = {
    modules = [ ];
    message = "Expected diagnostic";
  };
  longArtifact = "artifact-" + lib.concatStrings (lib.replicate 128 "a");
in
assert forceEval base;
assert
  builtins.attrNames (validate base) == [
    "builds"
    "eval"
    "fails"
    "run"
    "vm"
  ];
assert
  (validate base).fails == { }
  && (validate base).run == { }
  && (validate base).builds == { }
  && (validate base).vm == { };
assert rejects forceEval [ ];
assert rejects forceEval { };
assert rejects forceEval { eval = { }; };
assert rejects forceEval (base // { extra = { }; });
assert rejects forceEval { eval = true; };
assert builtins.all (value: rejects forceEval { eval.promise = value; }) [
  false
  null
  1
  "true"
  { }
  [ true ]
  (value: value)
];
assert rejects forceEval { eval."BadName" = true; };
assert rejects forceEval { eval."invalid/name" = true; };
assert forceEval {
  eval."line-1.2" = true;
  eval.camelCase = true;
};
assert forceFails (base // { fails.expected = validFailure; });
assert builtins.length complete.fails.expected.modules == 2;
assert complete.fails.expected.message == "Expected diagnostic";
assert builtins.all (value: rejects forceFails (base // { fails.expected = value; })) [
  true
  { }
  { modules = [ ]; }
  { message = "Expected diagnostic"; }
  {
    modules = [ ];
    message = "Expected diagnostic";
    extra = true;
  }
  {
    modules = { };
    message = "Expected diagnostic";
  }
  {
    modules = [ ];
    message = "";
  }
  {
    modules = [ ];
    message = 1;
  }
];
assert rejects forceFails (base // { fails = [ ]; });
assert rejects forceFails (base // { fails."invalid:name" = validFailure; });
assert builtins.all
  (
    group:
    forceDerivations group (base // { ${group}.activation = fixture; })
    && rejects (forceDerivations group) (base // { ${group}.activation = foreign; })
    && rejects (forceDerivations group) (
      base // { ${group}.activation = builtins.removeAttrs fixture [ "system" ]; }
    )
    && rejects (forceDerivations group) (base // { ${group}.activation = "not a derivation"; })
    && rejects (forceDerivations group) (base // { ${group} = [ ]; })
    && rejects (forceDerivations group) (base // { ${group}."invalid/name" = fixture; })
  )
  [
    "run"
    "builds"
    "vm"
  ];
assert rejects (forceDerivations "vm") (base // { vm.other = fixture; });
assert forceDerivations "builds" (base // { builds.${longArtifact} = fixture; });
assert builtins.all
  (
    group:
    let
      value =
        complete.${group}.${
          if group == "run" then
            "commands"
          else if group == "builds" then
            "application"
          else
            "activation"
        };
    in
    value.drvPath == fixture.drvPath
    && value.system == fixture.system
    && value.marker == "original"
    && value.passthru.recursive.marker == "original"
  )
  [
    "run"
    "builds"
    "vm"
  ];

assert forceEval (base // { run = throw "Unselected run group was forced"; });
assert forceDerivations "run" {
  eval.promise = throw "Unselected eval leaf was forced";
  run.commands = fixture;
};
true
