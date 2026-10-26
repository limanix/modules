# Find module directories in the result of builtins.readDir.
#
# Regular files and the reserved _shared entry are skipped.
# Every remaining entry must be a directory; links are rejected.
# catalog.nix uses these names to read each module's public files.
entries:
map
  (
    name:
    if entries.${name} == "directory" then name else throw "Module catalog: ${name} must be a directory"
  )
  (
    builtins.filter (name: name != "_shared" && entries.${name} != "regular") (
      builtins.attrNames entries
    )
  )
