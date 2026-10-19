# Resolves one version line of a module's releases.nix. A line comes from the base Nixpkgs, from
# the catalog's nixos-unstable revision in unstable.toml, or from a snapshot { rev, sha256 }.
# Lines from the base and unstable follow their patch releases; a snapshot keeps its exact version.
{
  # The module's releases.nix, as a path: its directory names the module in diagnostics.
  releases,
  line,
  pkgs,
  pinned,
}:
let
  inherit (pkgs) lib;
  name = baseNameOf (dirOf releases);
  fail = message: throw "${name}: line ${line}: ${message}";
  records = import releases;
  record = records.${line} or (fail "missing from releases.nix");
  source = record.source or (fail "needs a source");
  moving = source == "base" || source == "unstable";
  snapshot = builtins.isAttrs source;

  revision =
    what: value:
    if
      builtins.isAttrs value
      &&
        builtins.attrNames value == [
          "rev"
          "sha256"
        ]
      && builtins.match "[0-9a-f]{40}" value.rev != null
      && builtins.match "sha256-[A-Za-z0-9+/]{43}=" value.sha256 != null
    then
      value
    else
      fail "${what} needs exactly a full rev and an SRI sha256";
  unstable = revision "the unstable revision" (
    builtins.fromTOML (builtins.readFile ../unstable.toml)
  );
  revisionOf =
    value:
    if value == "base" then
      null
    else if value == "unstable" then
      unstable
    else if builtins.isAttrs value then
      revision "a snapshot" value
    else
      fail ''source must be "base", "unstable" or a snapshot { rev, sha256 }'';
  # The package set of a source and the pin it declares. Pins never evaluate a package set.
  resolve =
    value:
    let
      found = revisionOf value;
    in
    {
      packages = if found == null then pkgs else pinned.${found.rev};
      pins = lib.optionalAttrs (found != null) { ${found.rev} = found.sha256; };
    };

  checked =
    if !(moving || snapshot) then
      fail ''source must be "base", "unstable" or a snapshot { rev, sha256 }''
    else if !(builtins.isString (record.package or null)) then
      fail "needs a package attribute name"
    else if
      !(builtins.elem (record.endOfLife or "missing") [
        true
        false
        null
      ])
    then
      fail "needs endOfLife: true, false or null"
    else if moving && record ? version then
      fail "follows its source and records no version"
    else if snapshot && !(builtins.isString (record.version or null)) then
      fail "is a snapshot and needs its exact version"
    else
      builtins.seq (revisionOf source) record;
in
checked
// resolve source
// {
  inherit resolve;
  # Whether a package version belongs to this line.
  matches = version: if moving then lib.hasPrefix "${line}." version else version == record.version;
}
