let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
in
{
  imports = [ (./versions + "/${metadata.default}.nix") ];
}
