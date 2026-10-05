{
  evalSystem,
  pkgs,
  lib,
}:
let
  packagePriority =
    package:
    if builtins.isAttrs package then
      package.meta.priority or lib.meta.defaultPriority
    else
      lib.meta.defaultPriority;
  installed =
    configuration: package:
    builtins.any (
      candidate: toString candidate == toString package
    ) configuration.config.environment.systemPackages;
  selectedPackage =
    configuration: package:
    let
      identity =
        candidate:
        let
          pname = if builtins.isAttrs candidate then candidate.pname or null else null;
          name = if builtins.isAttrs candidate then candidate.name or null else null;
          valid = value: builtins.isString value && value != "";
        in
        if valid pname then
          pname
        else if valid name then
          name
        else
          null;
      selectedIdentity = identity package;
      candidates = builtins.filter (
        candidate:
        toString candidate == toString package
        || (selectedIdentity != null && identity candidate == selectedIdentity)
      ) configuration.config.environment.systemPackages;
      matching = builtins.filter (candidate: toString candidate == toString package) candidates;
    in
    matching != [ ]
    && builtins.all (
      candidate:
      toString candidate == toString package
      || builtins.any (winner: packagePriority winner < packagePriority candidate) matching
    ) candidates;
in
{
  inherit installed selectedPackage packagePriority;
  evaluate = modules: {
    config = evalSystem modules;
    inherit pkgs lib;
  };
  profileFor = configuration: configuration.config.system.path;
  verify =
    label: valid: _:
    if !builtins.isBool valid then
      throw "Module test: ${label}: expected a Boolean"
    else if valid then
      true
    else
      throw "Module test: ${label}";
  installedAsDeclared =
    configuration: package:
    builtins.any (
      candidate:
      toString candidate == toString package && packagePriority candidate == packagePriority package
    ) configuration.config.environment.systemPackages;
}
