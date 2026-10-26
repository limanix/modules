# A module with version lines: releases.nix names the lines, default.nix recommends the default
# one, versions/<line>.nix selects a line, and every selected line installs its packages and warns
# at end of life. The module's own file supplies what differs between lines of different modules.
spec:
{
  config,
  lib,
  pkgs,
  pinned,
  ...
}:
let
  inherit (spec) name directory;
  metadata = builtins.fromTOML (builtins.readFile (directory + "/module.toml"));
  lines = builtins.attrNames (import (directory + "/releases.nix"));
  selected = lib.unique config.lmx.internal.${name}.versions;
  sorted = builtins.sort lib.versionOlder selected;
  single = spec.single or false;
  active = version: builtins.elem version selected && (!single || builtins.length selected == 1);
  versionOf = line: config.lmx.internal.${name}.packages.${line}.${spec.main}.version;

  line =
    version:
    let
      release = import ./release.nix {
        releases = directory + "/releases.nix";
        line = version;
        inherit pkgs pinned;
      };
      tools = spec.packages { inherit version pinned pkgs; };
      rank = builtins.length (builtins.filter (other: lib.versionOlder other version) lines);
      priority = lib.meta.defaultPriority - (spec.priorityOffset or 0) - rank;
    in
    lib.mkMerge [
      {
        lmx = {
          inherit (release) pins;
          internal.${name}.packages.${version} = tools;
        };

        warnings =
          lib.optional (tools.endOfLife == true)
            "${spec.product or spec.title} ${tools.${spec.main}.version} no longer receives upstream security updates.";
      }
      ((spec.line or (_: { })) {
        inherit
          version
          tools
          rank
          priority
          config
          lib
          pkgs
          ;
      })
    ];
in
{
  options.lmx.internal.${name} = {
    versions = lib.mkOption {
      type = lib.types.listOf (lib.types.enum lines);
      default = [ ];
      internal = true;
      visible = false;
      description = "${name} version lines selected by catalog modules.";
    };
    packages = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      internal = true;
      visible = false;
      description = "Package records of the selected ${name} lines.";
    };
  };

  config = lib.mkMerge (
    [
      {
        lmx.internal.${name}.versions = lib.mkDefault [ metadata.default ];

        assertions = lib.optional single {
          assertion = builtins.length selected == 1;
          message = "${name}: select one line";
        };

        limanix.help.${name} = {
          title = "${spec.title} ${lib.concatStringsSep ", " (map versionOf sorted)}";
          summary = metadata.description;
          commands = spec.commands ++ lib.concatMap (spec.versioned or (_: [ ])) sorted;
          inherit (spec) tips;
          guide = "https://docs.limanix.dev/${spec.page}";
        };
      }
      ((spec.extra or (_: { })) { inherit config lib pkgs; })
    ]
    ++ map (version: lib.mkIf (active version) (line version)) lines
  );
}
