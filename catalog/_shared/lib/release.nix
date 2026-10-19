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
  resolve =
    value:
    import ./source.nix {
      source = value;
      inherit pkgs pinned fail;
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
      builtins.seq (resolve source).pins record;
in
checked
// resolve source
// {
  inherit resolve;
  matches = version: if moving then lib.hasPrefix "${line}." version else version == record.version;
}
