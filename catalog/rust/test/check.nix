{
  config,
  pkgs,
  tools,
  hasPackage,
  ...
}:
let
  warning = "Rust ${tools.rustc.version} no longer receives upstream security updates.";
in
builtins.all hasPackage [
  tools.rustc
  tools.cargo
  tools.rustfmt
  tools.clippy
  config.lmx.capabilities.languageSupport.tools.rust-analyzer.package
  pkgs.gcc
  pkgs.pkg-config
  pkgs.gdb
]
&& builtins.elem "rust" config.lmx.capabilities.languageSupport.languages.rust.parsers
&& (builtins.elem warning config.warnings == (tools.endOfLife == true))
