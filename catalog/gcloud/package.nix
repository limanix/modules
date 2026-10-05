# The CLI with the components this module installs on top of the base package.
{ pkgs, lib }:
let
  inherit (pkgs) google-cloud-sdk;
  inherit (google-cloud-sdk) components;
  extra = [ components.gke-gcloud-auth-plugin ];
  joined = [
    components.alpha
    components.beta
  ]
  ++ lib.concatMap (component: [ component ] ++ component.dependencies) extra;
in
{
  package = google-cloud-sdk.withExtraComponents extra;
  localBuilds = joined ++ builtins.filter lib.isDerivation (map (component: component.src) joined);
}
