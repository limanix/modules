{ config, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  limanix.help.rust = {
    title = "Rust ${config.lmx.rust.toolchain}";
    summary = metadata.description;
    commands = [
      "rustup"
      "cargo"
      "rustc"
      "rustfmt"
      "rust-analyzer"
      "gdb"
      "gcc"
      "pkg-config"
    ];
    tips = [
      {
        label = "Toolchain";
        text = "rustup show";
      }
      {
        label = "Pin";
        text = "Add rust-toolchain.toml to pin the version of a project.";
      }
      {
        label = "Run tests";
        text = "cargo test";
      }
      {
        label = "Lint";
        text = "cargo fmt && cargo clippy";
      }
    ];
    guide = "https://docs.limanix.dev/modules/rust";
  };
}
