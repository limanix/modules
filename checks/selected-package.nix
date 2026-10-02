{ packagePriority }:
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
) candidates
