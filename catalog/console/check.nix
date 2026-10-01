args:
builtins.all (entry: import (builtins.dirOf entry + "/check.nix") args) (import ./components.nix)
