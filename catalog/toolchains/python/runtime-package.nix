{ lib, python }:

builtins.removeAttrs (lib.getBin python) [ "doc" ]
