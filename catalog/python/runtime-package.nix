{ lib, python }:
# NixOS appends optional HTML docs even when the interpreter output is explicit.
# Keep the original SDK available through packages.nix; install its runtime here.
# Apply priority first: later derivation overrides can restore the doc passthru.
builtins.removeAttrs (lib.getBin python) [ "doc" ]
