{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.runCommand "example" { } ''mkdir -p "$out/bin"; touch "$out/bin/example"'')
  ];
}
