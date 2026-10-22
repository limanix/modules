# Installs the declared default toolchain of the development account once per declaration.
# A default that the user chose later with `rustup default` stays until the declaration changes.
#
# Usage: rust-toolchain-setup TOOLCHAIN COMPONENTS
set -eu

toolchain=$1
components=$2
home=${RUSTUP_HOME:-$HOME/.rustup}
marker=$home/limanix-toolchain

if [ "$(cat "$marker" 2>/dev/null || true)" = "$toolchain" ] && rustup default >/dev/null 2>&1; then
  exit 0
fi

# The minimal profile leaves out rust-docs, tens of thousands of files that a VM rarely reads.
rustup toolchain install "$toolchain" --profile minimal --component "$components"
rustup default "$toolchain"
printf '%s\n' "$toolchain" >"$marker"
