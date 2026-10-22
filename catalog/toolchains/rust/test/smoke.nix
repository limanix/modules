{
  pkgs,
  components,
  profile,
  overrideProfile,
  setups,
}:
let
  # Rust from Nixpkgs stands in for a downloaded toolchain, so the proxies run offline.
  linked = pkgs.symlinkJoin {
    name = "rust-linked-toolchain";
    paths = [
      pkgs.rustc
      pkgs.cargo
      pkgs.rustfmt
      pkgs.clippy
      pkgs.rust-analyzer
    ];
    # rustup links only a directory with bin/rustc and lib/.
    postBuild = ''mkdir -p "$out/lib"'';
  };
  # Records each call and keeps the default toolchain the way rustup does.
  fakeRustup = pkgs.writeShellScript "rustup" ''
    set -eu
    printf '%s\n' "$*" >>"$LOG"
    home=''${RUSTUP_HOME:-$HOME/.rustup}
    case "$*" in
      default)
        cat "$home/default" 2>/dev/null || exit 1
        ;;
      "default "*)
        mkdir -p "$home"
        printf '%s\n' "$2" >"$home/default"
        ;;
      "toolchain install "*)
        test -z "''${FAIL_INSTALL:-}" || exit 1
        mkdir -p "$home"
        ;;
      *)
        exit 2
        ;;
    esac
  '';
in
{
  commands = pkgs.runCommand "rust-commands-smoke" { nativeBuildInputs = [ profile ]; } ''
    export HOME="$TMPDIR/home" RUSTUP_HOME="$TMPDIR/rustup" CARGO_HOME="$TMPDIR/cargo"
    mkdir -p "$HOME"

    rustup="$(readlink -f ${pkgs.rustup}/bin/rustup)"
    for command in cargo rustc rustdoc rustfmt cargo-fmt cargo-clippy clippy-driver rust-analyzer rust-gdb; do
      test "$(readlink -f ${profile}/bin/$command)" = "$rustup"
    done
    test "$(command -v cc)" = ${profile}/bin/cc
    rustup --version
    gdb --version
    pkg-config --version

    # No default toolchain yet: the proxies fail instead of reaching the network.
    if cargo --version; then
      echo "cargo ran without a toolchain" >&2
      exit 1
    fi

    rustup toolchain link nixpkgs ${linked}
    rustup default nixpkgs
    rustc --version | grep -F '${pkgs.rustc.version}'
    rust-analyzer --version
    cargo new --vcs none example
    cd example
    cargo build --offline
    cargo test --offline
    cargo fmt -- --check
    cargo clippy --offline -- -D warnings
    touch "$out"
  '';

  userOverride = pkgs.runCommand "rust-user-selected-provider" { } ''
    test "$(readlink -f ${overrideProfile}/bin/rust-analyzer)" = \
      "$(readlink -f ${pkgs.rust-analyzer}/bin/rust-analyzer)"
    test "$(readlink -f ${overrideProfile}/bin/cargo)" = "$(readlink -f ${pkgs.rustup}/bin/rustup)"
    ${overrideProfile}/bin/rust-analyzer --version
    touch "$out"
  '';

  toolchainSetup = pkgs.runCommand "rust-toolchain-setup-smoke" { } ''
    export HOME="$TMPDIR/home" LOG="$TMPDIR/rustup.log"
    mkdir -p "$HOME" "$TMPDIR/bin"
    ln -s ${fakeRustup} "$TMPDIR/bin/rustup"
    export PATH="$TMPDIR/bin:$PATH"
    marker="$HOME/.rustup/limanix-toolchain"
    calls() { grep -c -F -x -- "$1" "$LOG" || true; }

    # A failed download leaves no marker, so the unit fails and systemd retries.
    if FAIL_INSTALL=1 ${setups.stable}; then
      echo "setup succeeded although the download failed" >&2
      exit 1
    fi
    test ! -e "$marker"

    : >"$LOG"
    ${setups.stable}
    test "$(calls 'toolchain install stable --profile minimal --component ${components}')" = 1
    test "$(calls 'default stable')" = 1
    test "$(cat "$marker")" = stable

    # Unchanged declaration: nothing is installed again, and the user's own default stays.
    rustup default nightly
    : >"$LOG"
    ${setups.stable}
    test "$(cat "$LOG")" = default
    test "$(cat "$HOME/.rustup/default")" = nightly

    # A changed declaration installs and selects the new toolchain.
    : >"$LOG"
    ${setups.pinned}
    test "$(calls 'toolchain install 1.90.0 --profile minimal --component ${components}')" = 1
    test "$(calls 'default 1.90.0')" = 1
    test "$(cat "$marker")" = 1.90.0
    touch "$out"
  '';
}
