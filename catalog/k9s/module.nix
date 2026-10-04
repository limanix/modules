{ version }:
{ ... }:
{
  imports = [ ./selection.nix ];
  lmx.internal.k9s.versions = [ version ];
}
