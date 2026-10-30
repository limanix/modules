# The SGR parameters that draw a theme color in the foreground: one of the terminal's 16 colors by
# number, a palette's #rrggbb as 24-bit color, or null for the terminal's default foreground.
lib: color:
if color == null then
  "39"
else if builtins.isInt color then
  toString (if color < 8 then 30 + color else 90 + color - 8)
else
  "38;2;"
  +
    lib.concatMapStringsSep ";" (start: toString (lib.fromHexString (builtins.substring start 2 color)))
      [
        1
        3
        5
      ]
