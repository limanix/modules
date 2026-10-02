{
  catalog,
  module,
  defaultConfiguration,
  evaluate,
  pkgs,
  installed,
  capability,
  componentChecks,
  defaultVersionEntryPoint,
  verify,
  ...
}:
let
  defaultsOverride = evaluate [
    module.path
    {
      programs.neovim.defaultEditor = false;
      programs.nix-ld.enable = false;
    }
  ];
  entry = name: builtins.head (builtins.filter (entry: entry.name == name) catalog);
  providerTools =
    name:
    import (../. + "/${name}/packages.nix") {
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (entry name) version;
    };
in
{
  evaluation = {
    defaultEntryPoint = defaultVersionEntryPoint;
    composition = componentChecks;
    dependencies = verify "the editor and Lazygit are installed" (
      installed defaultConfiguration defaultConfiguration.config.programs.neovim.finalPackage
      && installed defaultConfiguration defaultConfiguration.config.programs.lazygit.package
    ) defaultConfiguration;
    defaults = verify "ordinary editor and nix-ld overrides" (
      !defaultsOverride.config.programs.neovim.defaultEditor
      && !defaultsOverride.config.programs.nix-ld.enable
      && defaultsOverride.config.programs.neovim.enable
    ) defaultsOverride;
    providerIndependence = verify "selection does not install optional language providers" (
      (capability defaultConfiguration).tools == { }
      && (capability defaultConfiguration).languages == { }
      && !(installed defaultConfiguration pkgs.pyright)
      && !(installed defaultConfiguration pkgs.typescript-language-server)
      &&
        builtins.all
          (
            provider:
            let
              tools = providerTools provider.name;
            in
            builtins.all (packageName: !(installed defaultConfiguration tools.${packageName})) provider.packages
          )
          [
            {
              name = "go";
              packages = [
                "go"
                "gopls"
                "delve"
              ];
            }
            {
              name = "rust";
              packages = [
                "rustc"
                "cargo"
                "rust-analyzer"
              ];
            }
            {
              name = "nodejs";
              packages = [ "nodejs" ];
            }
            {
              name = "python";
              packages = [
                "python"
                "virtualenv"
              ];
            }
          ]
    ) defaultConfiguration;
  };
}
