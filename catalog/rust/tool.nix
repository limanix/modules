{ config, ... }:
{
  environment.systemPackages = [
    config.lmx.capabilities.languageSupport.tools.rust-analyzer.package
  ];
}
