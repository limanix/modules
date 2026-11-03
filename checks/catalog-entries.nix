# Discover module directories, excluding regular files and _shared.
# Reject symlinks and other non-directory entries.
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
