# List the public module kinds and their directory order under catalog/.
#
# The order follows [shell], [toolchains], and nixos.modules in user settings.
# Catalog discovery and option ownership checks use this list.
# The Python planner and graph command also read it.
[
  "shell"
  "toolchains"
  "modules"
]
