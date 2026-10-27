{ pkgs }:
let
  prefix = pkgs.symlinkJoin {
    name = "compiler-test-prefix";
    paths = [
      pkgs.zlib
      pkgs.zlib.dev
      pkgs.glibc.dev
    ];
  };
  compiler = import ../lib/compiler.nix {
    compiler = pkgs.gcc;
    prefix = "${prefix}";
  };
  system = import ../lib/compiler.nix { compiler = pkgs.gcc; };
  rpath = "${pkgs.patchelf}/bin/patchelf --print-rpath";
in
pkgs.runCommandLocal "shared-compiler" { } ''
  export PATH="${compiler}/bin:$PATH"
  printf '#include <stdio.h>\n#include <zlib.h>\nint main(void) { puts(zlibVersion()); return 0; }\n' > zlib.c
  cc -o zlib zlib.c -lz
  ./zlib
  printf '#include <math.h>\nint main() { return abs(-1.5) == 1.5 ? 0 : 1; }\n' > overloads.cpp
  c++ -o overloads overloads.cpp
  ./overloads
  printf 'int main(void) { return 0; }\n' > empty.c
  ${system}/bin/cc -o empty empty.c
  ${rpath} empty | grep -q ':/run/current-system/sw/lib$'
  touch "$out"
''
