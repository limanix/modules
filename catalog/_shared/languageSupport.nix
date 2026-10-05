{ lib, ... }:
let
  toolDeclaration =
    type:
    type
    // {
      merge =
        loc: definitions:
        lib.mergeEqualOption loc (
          map (
            definition:
            definition
            // {
              value = type.merge loc [ definition ];
            }
          ) definitions
        );
      substSubModules = modules: toolDeclaration (type.substSubModules modules);
      typeMerge =
        other:
        let
          merged = type.typeMerge other;
        in
        if merged == null then null else toolDeclaration merged;
    };
in
{
  options.lmx.capabilities.languageSupport = {
    tools = lib.mkOption {
      default = { };
      description = "Language tools keyed by consumer-independent executable identity.";
      type = lib.types.attrsOf (
        toolDeclaration (
          lib.types.submodule {
            options = {
              package = lib.mkOption {
                type = lib.types.package;
                description = "Package supplying the declared executable.";
              };
              command = lib.mkOption {
                type = lib.types.str;
                description = "Executable used to launch this tool.";
              };
              args = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Arguments passed to the executable.";
              };
              languages = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Consumer-independent language identities supported by this tool.";
              };
            };
          }
        )
      );
    };
    languages = lib.mkOption {
      default = { };
      description = "Language declarations independent of language-server installation.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.parsers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            apply = lib.unique;
            description = "Parser identities required for this language.";
          };
        }
      );
    };
  };
}
