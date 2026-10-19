{ pkgs, pinned, ... }:
let
  # The CLI follows the catalog's nixos-unstable revision: upstream releases it every few days.
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
  # The catalog pins the version: keep claude update and claude install from
  # placing a separate self-updating copy under ~/.local.
  environment.sessionVariables.DISABLE_UPDATES = "1";
}
