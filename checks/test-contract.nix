# Validate the public test ABI without forcing derivation implementation attrs.
{
  lib,
  system,
  name,
}:
test:
let
  groups = [
    "eval"
    "fails"
    "run"
    "builds"
    "vm"
  ];
  require = condition: message: if condition then true else throw "Module tests: ${name}: ${message}";
  validKey = key: builtins.match "[a-z][A-Za-z0-9._-]*" key != null;
  groupFor = group: test.${group} or { };
  validateKeys =
    group: values:
    assert require (builtins.isAttrs values) "${group} must be an attribute set";
    assert require (builtins.all validKey (
      builtins.attrNames values
    )) "${group} has an invalid export name";
    values;
  validateEval =
    let
      values = validateKeys "eval" test.eval;
    in
    assert require (builtins.all (
      key:
      let
        value = values.${key};
      in
      require (builtins.isBool value && value) "eval.${key} must be the Boolean true"
    ) (builtins.attrNames values)) "invalid eval result";
    values;
  validateFailure =
    key: value:
    assert require (builtins.isAttrs value) "fails.${key} must be an attribute set";
    assert require (
      builtins.attrNames value == [
        "message"
        "modules"
      ]
    ) "fails.${key} must contain only modules and message";
    assert require (builtins.isList value.modules) "fails.${key}.modules must be a list";
    assert require (
      builtins.isString value.message && value.message != ""
    ) "fails.${key}.message must be a nonempty string";
    value;
  validateFails =
    let
      values = validateKeys "fails" (groupFor "fails");
    in
    assert require (builtins.all (key: builtins.seq (validateFailure key values.${key}) true) (
      builtins.attrNames values
    )) "invalid fails result";
    values;
  validateDerivations =
    group:
    let
      values = validateKeys group (groupFor group);
    in
    assert require (
      group != "vm" || builtins.all (key: key == "activation") (builtins.attrNames values)
    ) "vm may export only activation";
    assert require (builtins.all (
      key:
      let
        value = values.${key};
      in
      require (
        lib.isDerivation value && (value.system or null) == system
      ) "${group}.${key} must be a derivation for ${system}"
    ) (builtins.attrNames values)) "invalid derivation group";
    values;
in
assert require (builtins.isAttrs test) "test.nix must return an attribute set";
assert require (builtins.all (key: builtins.elem key groups) (
  builtins.attrNames test
)) "test.nix returned an unknown group";
assert require (
  test ? eval && builtins.isAttrs test.eval && builtins.attrNames test.eval != [ ]
) "eval must be a nonempty attribute set";
{
  eval = validateEval;
  fails = validateFails;
  run = validateDerivations "run";
  builds = validateDerivations "builds";
  vm = validateDerivations "vm";
}
