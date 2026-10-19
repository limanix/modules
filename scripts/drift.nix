# Compares every release map with the lines that the base Nixpkgs and the catalog's nixos-unstable
# revision carry, by the source rule of writing-modules.md, and renders the findings as Markdown.
#
# Usage: nix eval --json --impure --file scripts/drift.nix
#        nix eval --raw --impure --file scripts/drift.nix markdown
let
  catalog = ../catalog;
  lock = (builtins.fromJSON (builtins.readFile ../flake.lock)).nodes.nixpkgs;
  unstableRevision = builtins.fromTOML (builtins.readFile (catalog + "/_shared/unstable.toml"));

  sources = {
    base = import ../checks/nixpkgs.nix;
    unstable = builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${unstableRevision.rev}.tar.gz";
      inherit (unstableRevision) sha256;
    };
  };
  lib = import (sources.base + "/lib");
  sets = builtins.mapAttrs (
    _: source:
    import source {
      system = builtins.currentSystem;
      overlays = [ ];
      config = {
        allowAliases = false;
        allowUnfree = true;
      };
    }
  ) sources;

  atLeast = version: other: builtins.compareVersions version other >= 0;
  byVersion = builtins.sort (left: right: builtins.compareVersions left right < 0);
  isReleased =
    version: builtins.isString version && builtins.match "[0-9]+(\\.[0-9]+)*" version != null;
  lineOf = depth: version: lib.concatStringsSep "." (lib.take depth (lib.splitString "." version));

  attributesOf =
    line: package: set:
    let
      suffixes = [
        (builtins.replaceStrings [ "." ] [ "_" ] line)
        (builtins.replaceStrings [ "." ] [ "" ] line)
      ];
      suffix = lib.findFirst (candidate: lib.hasSuffix candidate package) null suffixes;
      prefix = lib.removeSuffix suffix package;
      isMember =
        name: lib.hasPrefix prefix name && builtins.match "[0-9_]+" (lib.removePrefix prefix name) != null;
    in
    if suffix == null || prefix == "" then
      [ package ]
    else
      builtins.filter isMember (builtins.attrNames set);

  versionOf =
    set: name:
    let
      value = set.${name};
      attempt = builtins.tryEval (value.version or value.packages.stable.rustc.version or null);
    in
    if attempt.success then attempt.value else null;

  linesIn =
    depth: names: set:
    let
      versions = builtins.filter isReleased (map (versionOf set) names);
    in
    builtins.mapAttrs (_: lib.last) (lib.groupBy (lineOf depth) (byVersion versions));

  findingsOf =
    name:
    let
      records = import (catalog + "/${name}/releases.nix");
      lines = byVersion (builtins.attrNames records);
      oldest = builtins.head lines;
      newest = lib.last lines;
      depth = builtins.length (lib.splitString "." newest);
      carried = builtins.mapAttrs (
        _: set: linesIn depth (attributesOf newest records.${newest}.package set) set
      ) sets;
      finding = line: text: { inherit name line text; };

      checks = {
        base =
          { line, base, ... }:
          lib.optional (base == null) (finding line "No longer in the base: freeze it on a snapshot");
        unstable =
          {
            line,
            base,
            unstable,
            ...
          }:
          if unstable == null then
            [ (finding line "No longer in nixos-unstable: freeze it on its previous revision") ]
          else
            lib.optional (base != null && atLeast base unstable) (
              finding line "The base has ${base}: take the line from the base"
            );
        snapshot =
          {
            line,
            record,
            base,
            unstable,
          }:
          if base != null && atLeast base record.version then
            [ (finding line "Snapshot ${record.version}: the base has ${base}") ]
          else
            lib.optional (unstable != null && atLeast unstable record.version) (
              finding line "Snapshot ${record.version}: nixos-unstable has ${unstable}"
            );
      };
      check =
        line:
        let
          record = records.${line};
          kind = if builtins.isAttrs record.source then "snapshot" else record.source;
        in
        checks.${kind} {
          inherit line record;
          base = carried.base.${line} or null;
          unstable = carried.unstable.${line} or null;
        };

      isNew = line: !(records ? ${line}) && builtins.compareVersions line oldest > 0;
      newLines = byVersion (
        builtins.filter isNew (
          lib.unique (builtins.attrNames carried.base ++ builtins.attrNames carried.unstable)
        )
      );
      offer =
        line:
        let
          source = if carried.base ? ${line} then "the base" else "nixos-unstable";
          version = carried.base.${line} or carried.unstable.${line};
        in
        finding line "New line in ${source} (${version})";
    in
    builtins.concatMap check lines ++ map offer newLines;

  hasReleaseMap =
    name:
    let
      file = catalog + "/${name}/releases.nix";
    in
    builtins.pathExists file
    && builtins.all (record: record ? source) (builtins.attrValues (import file));
  modules = builtins.filter hasReleaseMap (builtins.attrNames (builtins.readDir catalog));

  findings = builtins.concatMap findingsOf modules;
  short = revision: builtins.substring 0 7 revision;
  revisions = "Base: `${short lock.locked.rev}` (${lock.original.ref}). nixos-unstable: `${short unstableRevision.rev}`.";
  row = item: "| ${item.name} | ${item.line} | ${item.text} |";
  document = lines: lib.concatStringsSep "\n" lines + "\n";
in
{
  findings = builtins.length findings;
  markdown =
    if findings == [ ] then
      document [
        "The catalog's lines match their sources."
        ""
        revisions
      ]
    else
      document (
        [
          "Lines that differ from their sources by the rule in [Support multiple versions](guides/writing-modules.md#support-multiple-versions)."
          "Edit the module's `releases.nix`, its `module.toml` and README, then let CI check the change."
          ""
          revisions
          ""
          "| Module | Line | Finding |"
          "| -- | -- | -- |"
        ]
        ++ map row findings
      );
}
