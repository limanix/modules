{ lib, sets }:
let
  atLeast = version: other: builtins.compareVersions version other >= 0;
  byVersion = builtins.sort (left: right: builtins.compareVersions left right < 0);
  isReleased =
    version:
    builtins.isString version && builtins.match "[0-9]+(\\.[0-9]+)*(\\+[0-9]+)?" version != null;
  lineOf =
    depth: version:
    lib.concatStringsSep "." (
      lib.take depth (lib.splitString "." (lib.head (lib.splitString "+" version)))
    );

  attributesOf =
    line: package: set:
    let
      encodings = [
        (builtins.replaceStrings [ "." ] [ "_" ] line)
        (builtins.replaceStrings [ "." ] [ "" ] line)
      ];
      parts = builtins.split "([0-9]+(_[0-9]+)*)" package;
      positions = builtins.filter (
        index:
        let
          part = builtins.elemAt parts index;
        in
        builtins.isList part && builtins.elem (builtins.head part) encodings
      ) (lib.range 0 (builtins.length parts - 1));
      position = builtins.head positions;
      text = part: if builtins.isString part then part else builtins.head part;
      prefix = lib.concatMapStrings text (lib.take position parts);
      suffix = lib.concatMapStrings text (lib.drop (position + 1) parts);
      isMember =
        name:
        lib.hasPrefix prefix name
        && lib.hasSuffix suffix name
        &&
          builtins.match "[0-9]+(_[0-9]+)*" (lib.removePrefix prefix (lib.removeSuffix suffix name)) != null;
    in
    if builtins.length positions != 1 || prefix == "" then
      [ package ]
    else
      builtins.filter isMember (builtins.attrNames set);

  versionOf =
    set: name:
    let
      value = set.${name};
      attempt = builtins.tryEval (value.version or null);
    in
    if attempt.success then attempt.value else null;

  linesIn =
    depth: names: set:
    let
      versions = builtins.filter isReleased (map (versionOf set) names);
    in
    builtins.mapAttrs (_: lib.last) (lib.groupBy (lineOf depth) (byVersion versions));

  findingsOf =
    { name, records }:
    let
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

in
findingsOf
