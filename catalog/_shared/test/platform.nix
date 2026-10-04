# Common public foundation for module-owned VM nodes. No application policy.
{
  userName ? "dev",
  userHome ? "/home/${userName}",
}:
{ config, lib, ... }:
let
  sharedDirectory = ../.;
  entries = builtins.readDir sharedDirectory;
  schemas = map (name: sharedDirectory + "/${name}") (
    builtins.filter (
      name: entries.${name} == "regular" && name != "test.nix" && lib.hasSuffix ".nix" name
    ) (builtins.attrNames entries)
  );
  priority =
    package:
    if builtins.isAttrs package then
      package.meta.priority or lib.meta.defaultPriority
    else
      lib.meta.defaultPriority;
in
{
  imports = [ ../../../interface.nix ] ++ schemas;
  options.environment.systemPackages = lib.mkOption {
    apply = lib.sort (
      left: right:
      if toString left == toString right then
        priority left < priority right
      else
        toString left < toString right
    );
  };
  config = {
    limanix.user = {
      name = lib.mkDefault userName;
      home = lib.mkDefault userHome;
    };
    system.stateVersion = config.system.nixos.release;
    users.users.${config.limanix.user.name} = {
      isNormalUser = true;
      uid = 1000;
      inherit (config.limanix.user) home shell;
    };
  };
}
