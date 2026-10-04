# Files are not modules. Non-file entries still need directory validation.
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
