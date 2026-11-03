# The keyword arguments of a Textual Theme that draws the guest's palette by role.
theme:
let
  inherit (theme) palette;
in
''primary="${palette.accent}", secondary="${palette.blue}", accent="${palette.orange}", warning="${palette.yellow}", error="${palette.red}", success="${palette.green}", foreground="${palette.foreground}", background="${palette.background}", surface="${palette.surface}", panel="${palette.selection}", dark=${
  if theme.dark then "True" else "False"
}''
