{
  nixpkgs,
  system,
}:
let
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;
  files = import ./shared-files.nix;
  checkFile =
    path:
    import ./shared-declarations.nix {
      inherit lib pkgs;
      modules = [ path ];
    };
in
builtins.all checkFile (files.public ++ files.private)
