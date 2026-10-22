{
  config,
  pkgs,
  lib,
  components,
  hasPackage,
}:
let
  analyzer = config.lmx.capabilities.languageSupport.tools.rust-analyzer;
  unit = config.systemd.user.services.rust-toolchain;
in
builtins.all hasPackage [
  pkgs.rustup
  pkgs.gcc
  pkgs.pkg-config
  pkgs.gdb
]
&& config.lmx.rust.toolchain == "stable"
&& builtins.elem "rust" config.lmx.capabilities.languageSupport.languages.rust.parsers
&& analyzer.package.outPath == pkgs.rustup.outPath
&& analyzer.command == "${pkgs.rustup}/bin/rust-analyzer"
&& analyzer.languages == [ "rust" ]
&& unit.wantedBy == [ "default.target" ]
&& unit.unitConfig.ConditionUser == config.limanix.user.name
&& unit.serviceConfig.Type == "oneshot"
&& unit.serviceConfig.Restart == "on-failure"
&& lib.hasSuffix " stable ${components}" unit.serviceConfig.ExecStart
&& lib.hasInfix ''PATH="$HOME/.cargo/bin:$PATH"'' config.environment.extraInit
&& config.limanix.help.rust.title == "Rust stable"
&& !config.programs.neovim.enable
