{ config, ... }:
{
  # Install the winner once, including an ordinary user declaration override.
  environment.systemPackages = [ config.lmx.capabilities.languageSupport.tools.gopls.package ];
}
