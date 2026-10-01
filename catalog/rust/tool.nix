{ config, ... }:
{
  environment.systemPackages = [ config.lmx.capabilities.editor.tools.rust-analyzer.package ];
}
