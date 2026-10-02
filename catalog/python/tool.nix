{ config, ... }:
{
  environment.systemPackages = [ config.lmx.capabilities.languageSupport.tools.pyright.package ];
}
