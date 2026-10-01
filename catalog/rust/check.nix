{
  config,
  pkgs,
  version,
  hasPackage,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  warning = "Rust ${tools.rustc.version} no longer receives upstream security updates.";
in
builtins.all hasPackage [
  tools.rustc
  tools.cargo
  tools.rustfmt
  tools.clippy
  config.lmx.capabilities.editor.tools.rust-analyzer.package
  pkgs.gcc
  pkgs.pkg-config
  pkgs.gdb
]
&& builtins.elem "rust" config.lmx.capabilities.editor.languages.rust.parsers
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
