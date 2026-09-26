version:
{ pkgs, lib, ... }:
let
  tools = import ./packages.nix {
    inherit version;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  releases = builtins.attrValues (import ./releases.nix).versions;
  olderReleases = builtins.filter (
    release: lib.versionOlder release.version tools.rustc.version
  ) releases;
  priority = lib.meta.defaultPriority - builtins.length olderReleases;

  toolchain = [
    tools.rustc
    tools.cargo
    tools.rustfmt
    tools.clippy
    tools.rust-analyzer
  ];

  versionedRust =
    pkgs.runCommand "rust-${version}-commands"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p "$out/bin"
        ln -s "${tools.rustc}/bin/rustc" "$out/bin/rustc-${version}"
        ln -s "${tools.rustc}/bin/rustdoc" "$out/bin/rustdoc-${version}"
        ln -s "${tools.rustfmt}/bin/rustfmt" "$out/bin/rustfmt-${version}"

        makeWrapper "${tools.cargo}/bin/cargo" "$out/bin/cargo-${version}" \
          --prefix PATH : "${lib.makeBinPath toolchain}"
        makeWrapper "${tools.rust-analyzer}/bin/rust-analyzer" "$out/bin/rust-analyzer-${version}" \
          --prefix PATH : "${lib.makeBinPath toolchain}"
      '';
in
{
  environment.systemPackages = map (lib.setPrio priority) toolchain ++ [
    versionedRust
    pkgs.gcc
    pkgs.pkg-config
    pkgs.gdb
  ];

  warnings = lib.optional tools.endOfLife "Rust ${tools.rustc.version} no longer receives upstream security updates.";
}
