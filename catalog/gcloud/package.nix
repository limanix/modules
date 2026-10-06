# The CLI with the components this module installs on top of the base package.
{ pkgs, lib }:
let
  inherit (pkgs) google-cloud-sdk;
  inherit (google-cloud-sdk) components;
  extra = [ components.gke-gcloud-auth-plugin ];
  preInstalled = with components; [
    bq
    bq-nix
    core
    core-nix
    gcloud-deps
    gcloud
    gsutil
    gsutil-nix
  ];
  closure =
    lib.converge
      (selected: lib.unique (selected ++ lib.concatMap (component: component.dependencies) selected))
      (
        [
          components.alpha
          components.beta
        ]
        ++ extra
      );
  joined = builtins.filter (component: !(builtins.elem component preInstalled)) closure;
in
{
  package = google-cloud-sdk.withExtraComponents extra;
  localBuilds = joined ++ builtins.filter lib.isDerivation (map (component: component.src) joined);
}
