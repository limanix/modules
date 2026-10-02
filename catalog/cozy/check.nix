args:
let
  checkComponent =
    entry:
    let
      directory = builtins.dirOf entry;
      metadata = builtins.fromTOML (builtins.readFile (directory + "/module.toml"));
      component = builtins.baseNameOf directory;
      versions = args.config.lmx.internal.${component}.versions or [ (metadata.default or null) ];
    in
    builtins.all (version: import (directory + "/check.nix") (args // { inherit version; })) versions;
in
builtins.all checkComponent (
  builtins.filter (entry: builtins.baseNameOf entry == "default.nix") (import ./components.nix)
)
&& builtins.any (package: package.name == "tmux-project") args.config.environment.systemPackages
