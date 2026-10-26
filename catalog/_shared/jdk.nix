{ lib, ... }:
{
  options.lmx.capabilities.jdk.package = lib.mkOption {
    type = lib.types.nullOr lib.types.package;
    default = null;
    description = "JDK that Java build tools and frameworks run on.";
  };
}
