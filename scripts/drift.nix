# Compares every release map with the lines that the base Nixpkgs and the catalog's nixos-unstable
# revision carry, by the source rule of writing-modules.md, and renders the findings as Markdown.
#
# Usage: nix eval --json --impure --file scripts/drift.nix
#        nix eval --raw --impure --file scripts/drift.nix markdown
let
  catalog = ../catalog;
  baseSource = import ../checks/nixpkgs.nix;
  unstableRevision = builtins.fromTOML (builtins.readFile (catalog + "/_shared/unstable.toml"));
  unstableSource = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${unstableRevision.rev}.tar.gz";
    inherit (unstableRevision) sha256;
  };
  lib = import (baseSource + "/lib");
  open =
    source:
    import source {
      system = builtins.currentSystem;
      overlays = [ ];
      config = {
        allowAliases = false;
        allowUnfree = true;
      };
    };
  sets = {
    base = open baseSource;
    unstable = open unstableSource;
  };
  lock = (builtins.fromJSON (builtins.readFile ../flake.lock)).nodes.nixpkgs;

  newer = left: right: builtins.compareVersions left right > 0;
  byVersion = builtins.sort (left: right: builtins.compareVersions left right < 0);
  released =
    version: builtins.isString version && builtins.match "[0-9]+(\\.[0-9]+)*" version != null;
  lineOf = depth: version: lib.concatStringsSep "." (lib.take depth (lib.splitString "." version));

  # The attributes that carry a module's lines: a family such as go_1_<minor> when the line is
  # part of the attribute name, otherwise the one attribute.
  family =
    line: package:
    let
      forms = [
        (builtins.replaceStrings [ "." ] [ "_" ] line)
        (builtins.replaceStrings [ "." ] [ "" ] line)
      ];
      form = lib.findFirst (candidate: lib.hasSuffix candidate package) null forms;
      prefix = if form == null then "" else lib.removeSuffix form package;
    in
    set:
    if prefix == "" then
      [ package ]
    else
      builtins.filter (
        name: lib.hasPrefix prefix name && builtins.match "[0-9_]+" (lib.removePrefix prefix name) != null
      ) (builtins.attrNames set);
  # A Rust attribute such as rust_1_98 is a package set: its compiler carries the version.
  versionOf = value: value.version or value.packages.stable.rustc.version or null;
  # The released lines of a package set and the newest version of each.
  available =
    depth: names: set:
    builtins.foldl' (
      lines: name:
      let
        attempt = builtins.tryEval (versionOf set.${name});
        version = if attempt.success && released attempt.value then attempt.value else null;
        line = lineOf depth version;
      in
      if version == null || (lines ? ${line} && !(newer version lines.${line})) then
        lines
      else
        lines // { ${line} = version; }
    ) { } names;

  modules = builtins.filter (
    name:
    builtins.pathExists (catalog + "/${name}/releases.nix")
    && builtins.all (record: record ? source) (
      builtins.attrValues (import (catalog + "/${name}/releases.nix"))
    )
  ) (builtins.attrNames (builtins.readDir catalog));

  findingsOf =
    name:
    let
      records = import (catalog + "/${name}/releases.nix");
      lines = byVersion (builtins.attrNames records);
      newest = lib.last lines;
      depth = builtins.length (lib.splitString "." newest);
      names = family newest records.${newest}.package;
      have = builtins.mapAttrs (_: set: available depth (names set) set) sets;
      finding = line: text: { inherit name line text; };
      check =
        line:
        let
          record = records.${line};
          inBase = have.base.${line} or null;
          inUnstable = have.unstable.${line} or null;
        in
        if record.source == "base" then
          lib.optional (inBase == null) (finding line "No longer in the base: freeze it on a snapshot")
        else if record.source == "unstable" then
          if inUnstable == null then
            [ (finding line "No longer in nixos-unstable: freeze it on its previous revision") ]
          else
            lib.optional (inBase != null && !(newer inUnstable inBase)) (
              finding line "The base has ${inBase}: take the line from the base"
            )
        else if inBase != null && !(newer record.version inBase) then
          [ (finding line "Snapshot ${record.version}: the base has ${inBase}") ]
        else
          lib.optional (inUnstable != null && !(newer record.version inUnstable)) (
            finding line "Snapshot ${record.version}: nixos-unstable has ${inUnstable}"
          );
      candidates = lib.unique (builtins.attrNames have.base ++ builtins.attrNames have.unstable);
      added = byVersion (
        builtins.filter (
          line: !(records ? ${line}) && builtins.compareVersions line (builtins.head lines) > 0
        ) candidates
      );
      offer =
        line:
        finding line (
          if have.base ? ${line} then
            "New line in the base (${have.base.${line}})"
          else
            "New line in nixos-unstable (${have.unstable.${line}})"
        );
    in
    builtins.concatMap check lines ++ map offer added;

  findings = builtins.concatMap findingsOf modules;
  short = revision: builtins.substring 0 7 revision;
  revisions = "Base: `${short lock.locked.rev}` (${lock.original.ref}). nixos-unstable: `${short unstableRevision.rev}`.";
  row = item: "| ${item.name} | ${item.line} | ${item.text} |";
in
{
  findings = builtins.length findings;
  markdown =
    if findings == [ ] then
      "The catalog's lines match their sources.\n\n${revisions}\n"
    else
      lib.concatStringsSep "\n" (
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
      )
      + "\n";
}
