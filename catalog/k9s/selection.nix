{
  config,
  pkgs,
  lib,
  ...
}:
let
  releases = (import ./releases.nix).versions;
  selected = builtins.map (
    version:
    import ./packages.nix {
      inherit version;
      inherit (pkgs.stdenv.hostPlatform) system;
    }
  ) (lib.unique config.lmx.internal.k9s.versions);
  priority =
    tools:
    lib.meta.defaultPriority
    - builtins.length (
      builtins.filter (release: lib.versionOlder release.version tools.k9s.version) (
        builtins.attrValues releases
      )
    );
in
{
  options.lmx.internal.k9s.versions = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (builtins.attrNames releases));
    default = [ ];
    internal = true;
    visible = false;
    description = "K9s version lines selected by catalog modules.";
  };

  config = {
    environment.systemPackages = builtins.map (tools: lib.setPrio (priority tools) tools.k9s) selected;
    warnings = builtins.concatMap (
      tools:
      lib.optional (
        tools.endOfLife == true
      ) "K9s ${tools.k9s.version} no longer receives upstream security updates."
    ) selected;
  };
}
