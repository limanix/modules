{ config, ... }:
{
  # Install the winner once, including an ordinary user declaration override.
  environment.systemPackages = [ config.lmx.capabilities.editor.tools.gopls.package ];
}
