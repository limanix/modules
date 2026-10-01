{
  config,
  pkgs,
  version,
  hasPackage,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  k9sVersions = config.lmx.internal.k9s.versions;
  warning = "Minikube ${tools.minikube.version} no longer receives upstream security updates.";
in
hasPackage tools.minikube
&& k9sVersions != [ ]
&& builtins.all (
  version:
  hasPackage
    (import ../k9s/packages.nix {
      inherit version;
      inherit (pkgs.stdenv.hostPlatform) system;
    }).k9s
) k9sVersions
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
