# Extend versioned modules with editor support.
# Recommend the newest selected line's server and debugger, unless the user overrides them.
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
        recommend =
          offer:
          lib.mkOverride ((spec.providerPriority or 1000) - rank) (
            offer // { package = lib.setPrio priority offer.package; }
          );
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
          tools.${spec.tool} = recommend (spec.provider { inherit tools pkgs; });
          debuggers = lib.optionalAttrs (spec ? debugger) {
            ${spec.debugger} = recommend (spec.debuggerProvider { inherit tools pkgs; });
          };
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
      let
        inherit (config.lmx.capabilities) languageSupport;
      in
      lib.mkMerge [
        {
          environment.systemPackages = [
            languageSupport.tools.${spec.tool}.package
          ]
          ++ lib.optional (spec ? debugger) languageSupport.debuggers.${spec.debugger}.package;
        }
        ((spec.extra or (_: { })) context)
      ];
  }
)
