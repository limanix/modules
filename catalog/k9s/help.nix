{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.k9s.versions);
  versions = map (line: config.lmx.internal.k9s.packages.${line}.k9s.version) selected;
in
{
  limanix.help.k9s = {
    title = "K9s ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [ "k9s" ] ++ map (line: "k9s-${line}") selected;
    tips = [
      {
        label = "Kubeconfig";
        text = "k9s --kubeconfig /path/to/kubeconfig";
      }
      {
        label = "Context";
        text = "k9s --context NAME";
      }
      {
        label = "Read only";
        text = "k9s --readonly";
      }
      {
        label = "Keys";
        text = "Press ? inside K9s to list its key bindings.";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/k9s/README.html";
  };
}
