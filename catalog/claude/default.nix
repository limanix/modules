{ pkgs, pinned, ... }:
let
  unstable = import ../_shared/lib/source.nix {
    source = "unstable";
    inherit pkgs pinned;
  };
in
{
  imports = [ ./help.nix ];

  nixpkgs.config.allowUnfreePackages = [ "claude-code" ];
  lmx.pins = unstable.pins;
  environment.systemPackages = [ unstable.packages.claude-code ];
  environment.sessionVariables.DISABLE_UPDATES = "1";
}
