# One language of [toolchains]: a module with version lines that also offers a language server
# to editors. Each line recommends its server with a rank, so the newest selected line wins, and
# the server that the configuration finally selects is installed.
spec:
import ./lines.nix (
  spec
  // {
    line =
      {
        version,
        tools,
        rank,
        priority,
        lib,
        pkgs,
        ...
      }:
      let
        offer = spec.provider { inherit tools pkgs; };
      in
      {
        assertions = [
          {
            assertion = rank >= 0 && rank < 100;
            message = "${spec.name}: provider recommendation rank must be between 0 and 99";
          }
        ];

        lmx.capabilities.languageSupport = {
          languages = builtins.mapAttrs (_: parsers: { inherit parsers; }) spec.parsers;
          tools.${spec.tool} = lib.mkOverride (1000 - rank) (
            offer // { package = lib.setPrio priority offer.package; }
          );
        };

        environment.systemPackages = spec.systemPackages {
          inherit
            version
            tools
            pkgs
            lib
            priority
            ;
        };
      };

    extra =
      { config, lib, ... }@context:
      lib.mkMerge [
        {
          environment.systemPackages = [
            config.lmx.capabilities.languageSupport.tools.${spec.tool}.package
          ];
        }
        ((spec.extra or (_: { })) context)
      ];
  }
)
