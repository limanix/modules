{
  config,
  pkgs,
  lib,
  pinned,
  ...
}:
let
  catalog = import ./releases.nix;
  releases = catalog.versions;
  versions = lib.unique config.lmx.internal.k9s.versions;
  inherit (config.lmx.internal.k9s) packages;
  selected = map (version: packages.${version}) versions;
  sources = lib.unique (
    lib.concatMap (
      version:
      let
        release = releases.${version};
      in
      [ release.source ] ++ lib.optional (release ? buildSource) release.buildSource
    ) versions
  );
  priority =
    tools:
    lib.meta.defaultPriority
    - builtins.length (
      builtins.filter (release: lib.versionOlder release.version tools.k9s.version) (
        builtins.attrValues releases
      )
    );
  versionCommand =
    version:
    pkgs.runCommandLocal "k9s-${version}-command" { } ''
      mkdir -p "$out/bin"
      ln -s "${packages.${version}.k9s}/bin/k9s" "$out/bin/k9s-${version}"
    '';
in
{
  imports = [ ./help.nix ];

  options.lmx.internal.k9s = {
    versions = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (builtins.attrNames releases));
      default = [ ];
      internal = true;
      visible = false;
      description = "K9s version lines selected by this module.";
    };
    packages = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.anything;
      readOnly = true;
      internal = true;
      visible = false;
      description = "Configured K9s packages reused only inside this module.";
    };
  };
  config = {
    lmx.pins = lib.listToAttrs (
      map (
        name:
        let
          source = catalog.sources.${name};
        in
        {
          name = source.rev;
          value = source.sha256;
        }
      ) sources
    );
    lmx.internal.k9s.packages = lib.genAttrs versions (
      version: import ./packages.nix { inherit version pinned; }
    );
    environment.systemPackages =
      map (tools: lib.setPrio (priority tools) tools.k9s) selected ++ map versionCommand versions;
    warnings = lib.concatMap (
      tools:
      lib.optional (
        tools.endOfLife == true
      ) "K9s ${tools.k9s.version} no longer receives upstream security updates."
    ) selected;
  };
}
