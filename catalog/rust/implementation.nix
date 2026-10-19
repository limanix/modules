version:
{
  pkgs,
  lib,
  pinned,
  ...
}:
let
  tools = import ./packages.nix {
    inherit version pinned pkgs;
  };

  release = import ../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) pins;
  # Lines rank by their numbers: lines from the base or unstable record no exact version.
  olderLines = builtins.filter (line: lib.versionOlder line version) (
    builtins.attrNames (import ./releases.nix)
  );
  rank = builtins.length olderLines;
  priority = lib.meta.defaultPriority - rank;

  toolchain = [
    tools.rustc
    tools.cargo
    tools.rustfmt
    tools.clippy
    tools.rust-analyzer
  ];

  versionedRust =
    pkgs.runCommandLocal "rust-${version}-commands"
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
  assertions = [
    {
      assertion = rank >= 0 && rank < 100;
      message = "rust: provider recommendation rank must be between 0 and 99";
    }
  ];

  lmx = {
    inherit pins;
    internal.rust.packages.${version} = tools;

    capabilities.languageSupport = {
      languages.rust.parsers = [ "rust" ];
      tools.rust-analyzer = lib.mkOverride (1000 - rank) {
        package = lib.setPrio priority tools.rust-analyzer;
        command = "${tools.rust-analyzer}/bin/rust-analyzer";
        languages = [ "rust" ];
      };
    };
  };

  environment.systemPackages =
    map (lib.setPrio priority) (lib.remove tools.rust-analyzer toolchain)
    ++ [
      versionedRust
      pkgs.gcc
      pkgs.pkg-config
      pkgs.gdb
    ];

  warnings = lib.optional (
    tools.endOfLife == true
  ) "Rust ${tools.rustc.version} no longer receives upstream security updates.";
}
