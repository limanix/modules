# Resolves a package source: "base", the catalog's nixos-unstable revision in unstable.toml, or a
# snapshot { rev, sha256 }. Returns its package set and the pin it declares in lmx.pins; the pin
# never evaluates a package set.
{
  source,
  pkgs,
  pinned,
  # Reports an invalid source; release.nix names the module and line.
  fail ? message: throw "Package source: ${message}",
}:
let
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
  found =
    if source == "base" then
      null
    else if source == "unstable" then
      revision "the unstable revision" (builtins.fromTOML (builtins.readFile ../unstable.toml))
    else if builtins.isAttrs source then
      revision "a snapshot" source
    else
      fail ''source must be "base", "unstable" or a snapshot { rev, sha256 }'';
in
{
  packages = if found == null then pkgs else pinned.${found.rev};
  pins = pkgs.lib.optionalAttrs (found != null) { ${found.rev} = found.sha256; };
}
