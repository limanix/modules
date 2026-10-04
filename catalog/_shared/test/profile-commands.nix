# Check explicit expected executable paths against the actual selected profile.
{
  pkgs,
  profile,
  expectedCommands,
}:
pkgs.runCommand "profile-command-selection" { } (
  pkgs.lib.concatStringsSep "\n" (
    pkgs.lib.mapAttrsToList (command: executable: ''
      test "$(readlink -f ${profile}/bin/${command})" = \
        "$(readlink -f ${pkgs.lib.escapeShellArg (toString executable)})"
    '') expectedCommands
  )
  + "\ntouch \"$out\"\n"
)
