{ config, ... }:
{
  environment.systemPackages = [
    config.lmx.capabilities.languageSupport.tools.typescript-language-server.package
  ];
}
