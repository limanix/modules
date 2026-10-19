{ config, ... }:
{
  environment.systemPackages = [ config.lmx.capabilities.languageSupport.tools.gopls.package ];
}
