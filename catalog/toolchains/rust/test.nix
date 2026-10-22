{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers)
    evaluate
    profileFor
    verify
    installed
    packagePriority
    ;
  components = "rustfmt,clippy,rust-analyzer,rust-src";
  defaults = evaluate [ ./default.nix ];
  pinned = evaluate [
    ./default.nix
    { lmx.rust.toolchain = "1.90.0"; }
  ];
  userOverride = evaluate [
    ./default.nix
    {
      lmx.capabilities.languageSupport.tools.rust-analyzer = {
        package = pkgs.rust-analyzer;
        command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        languages = [ "rust" ];
      };
    }
  ];
  unit = configuration: configuration.config.systemd.user.services.rust-toolchain;
  defaultsChecked = import ./test/check.nix {
    inherit (defaults) config;
    inherit pkgs lib components;
    hasPackage = installed defaults;
  };
  installedPriority =
    configuration: package:
    packagePriority (
      lib.findFirst (
        candidate: toString candidate == toString package
      ) null configuration.config.environment.systemPackages
    );
in
{
  eval = {
    defaults =
      verify "rust: rustup, native tools, parser, analyzer proxy and setup unit" defaultsChecked
        defaults;
    toolchain = verify "rust: the declared toolchain reaches the setup unit and the help card" (
      lib.hasSuffix " 1.90.0 ${components}" (unit pinned).serviceConfig.ExecStart
      && pinned.config.limanix.help.rust.title == "Rust 1.90.0"
    ) pinned;
    userOverride = verify "rust: a user-supplied rust-analyzer replaces the rustup proxy" (
      installed userOverride pkgs.rustup
      && installed userOverride pkgs.rust-analyzer
      && installedPriority userOverride pkgs.rust-analyzer < packagePriority pkgs.rustup
    ) userOverride;
  };
  fails.invalidToolchain = {
    modules = [
      ./default.nix
      { lmx.rust.toolchain = "latest"; }
    ];
    message = "lmx.rust.toolchain' is not of type";
  };
  run = import ./test/smoke.nix {
    inherit pkgs components;
    profile = profileFor defaults;
    overrideProfile = profileFor userOverride;
    setups = {
      stable = (unit defaults).serviceConfig.ExecStart;
      pinned = (unit pinned).serviceConfig.ExecStart;
    };
  };
}
