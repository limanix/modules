{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.rust.versions);
  versions = map (line: config.lmx.internal.rust.packages.${line}.rustc.version) selected;
  versioned = line: [
    "cargo-${line}"
    "rustc-${line}"
  ];
in
{
  limanix.help.rust = {
    title = "Rust ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [
      "cargo"
      "rustc"
      "rustfmt"
      "rust-analyzer"
      "gdb"
      "gcc"
      "pkg-config"
    ]
    ++ lib.concatMap versioned selected;
    tips = [
      {
        label = "New crate";
        text = "cargo new NAME";
      }
      {
        label = "Run tests";
        text = "cargo test";
      }
      {
        label = "Lint";
        text = "cargo fmt && cargo clippy";
      }
      {
        label = "Debug";
        text = "cargo build && gdb target/debug/NAME";
      }
    ];
    guide = "https://limanix.dev/categories/nixos/modules/rust/README.html";
  };
}
