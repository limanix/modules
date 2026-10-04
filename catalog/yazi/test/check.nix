{ config, hasPackage, ... }:
config.programs.yazi.enable
&& hasPackage (
  config.programs.yazi.package.override {
    inherit (config.programs.yazi)
      settings
      initLua
      plugins
      flavors
      ;
  }
)
