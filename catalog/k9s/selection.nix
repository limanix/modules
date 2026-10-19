{
  config,
  pkgs,
  lib,
  pinned,
  ...
}:
let
  releases = import ./releases.nix;
  versions = lib.unique config.lmx.internal.k9s.versions;
  inherit (config.lmx.internal.k9s) packages;
  selected = map (version: packages.${version}) versions;
  # Each selected line pins its own source and, when it has one, its compiler's.
  pinsOf =
    version:
    let
      release = import ../_shared/lib/release.nix {
        releases = ./releases.nix;
        line = version;
        inherit pkgs pinned;
      };
    in
    release.pins
    // lib.optionalAttrs (release ? buildSource) (release.resolve release.buildSource).pins;
  # Lines rank by their numbers: lines from the base or unstable record no exact version.
  priority =
    line:
    lib.meta.defaultPriority
    - builtins.length (
      builtins.filter (other: lib.versionOlder other line) (builtins.attrNames releases)
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
    lmx.pins = lib.foldl' (pins: version: pins // pinsOf version) { } versions;
    lmx.internal.k9s.packages = lib.genAttrs versions (
      version: import ./packages.nix { inherit version pinned pkgs; }
    );
    environment.systemPackages =
      map (version: lib.setPrio (priority version) packages.${version}.k9s) versions
      ++ map versionCommand versions;
    warnings = lib.concatMap (
      tools:
      lib.optional (
        tools.endOfLife == true
      ) "K9s ${tools.k9s.version} no longer receives upstream security updates."
    ) selected;
  };
}
