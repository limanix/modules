{ pkgs, selector, ... }:
{
  startup = pkgs.runCommand "contract-startup-${selector}" { } "touch $out";
}
