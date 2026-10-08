{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.minikube.versions);
  versions = map (line: config.lmx.internal.minikube.packages.${line}.minikube.version) selected;
in
{
  limanix.help.minikube = {
    title = "Minikube ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [ "minikube" ] ++ map (line: "minikube-${line}") selected;
    tips = [
      {
        label = "Start";
        text = "minikube start --driver=docker --profile=dev";
      }
      {
        label = "Status";
        text = "minikube status --profile=dev";
      }
      {
        label = "Pods";
        text = "minikube kubectl --profile=dev -- get pods -A";
      }
      {
        label = "Browse";
        text = "k9s --context dev";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/minikube/README.html";
  };
}
