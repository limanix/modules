{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  configuration = helpers.evaluate [ ./default.nix ];
  cfg = configuration.config;
  support = cfg.lmx.capabilities.languageSupport;

in
{
  eval = {
    languageSupport =
      builtins.all (name: builtins.hasAttr name support.tools) [
        "gopls"
        "pyright"
        "typescript-language-server"
      ]
      && builtins.all (name: builtins.hasAttr name support.languages) [
        "go"
        "python"
        "javascript"
        "typescript"
      ]
      && builtins.all (name: helpers.installed configuration support.tools.${name}.package) [
        "gopls"
        "pyright"
        "typescript-language-server"
      ];
    dockerAccess =
      cfg.virtualisation.docker.enable
      && builtins.elem "docker" cfg.users.users.${cfg.limanix.user.name}.extraGroups;
    workspace = builtins.any (
      package: builtins.isAttrs package && lib.getName package == "tmux-project"
    ) cfg.environment.systemPackages;
    noExamples =
      !builtins.any (
        path: path == "limanix/examples/cozy" || lib.hasPrefix "limanix/examples/cozy/" path
      ) (builtins.attrNames cfg.environment.etc);
  };
  run = import ./test/run.nix {
    inherit pkgs;
    profile = helpers.profileFor configuration;
    shell = "${cfg.limanix.user.shell}${cfg.limanix.user.shell.shellPath}";
  };
}
