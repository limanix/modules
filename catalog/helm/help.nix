{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.helm.versions);
  versions = map (line: config.lmx.internal.helm.packages.${line}.helm.version) selected;
in
{
  limanix.help.helm = {
    title = "Helm ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [ "helm" ] ++ map (line: "helm-${line}") selected;
    tips = [
      {
        label = "Releases";
        text = "helm list --all-namespaces --kubeconfig /path/to/kubeconfig";
      }
      {
        label = "Lint";
        text = "helm lint ./CHART";
      }
      {
        label = "Render";
        text = "helm template NAME ./CHART --set KEY=VALUE";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/helm/README.html";
  };
}
