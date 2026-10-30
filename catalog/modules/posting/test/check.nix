{ config, ... }:
builtins.any (package: (package.pname or "") == "posting") config.environment.systemPackages
&& config.environment.variables.POSTING_THEME == "limanix"
