{
  evalSystem,
  pkgs,
  lib,
}:
import ../../_shared/test/toolchain.nix {
  inherit evalSystem pkgs lib;
  spec = import ./toolchain.nix;
  coexisting = [
    "clang"
    "lldb"
  ];
  profileCommands = tools: {
    clang = "${tools.clang}/bin/clang";
    "clang++" = "${tools.clang}/bin/clang++";
    lldb = "${tools.lldb}/bin/lldb";
    clangd = "${tools.clang-tools}/bin/clangd";
  };
  commands =
    { line, profile, ... }:
    pkgs.runCommandLocal "clang-${line}-commands-smoke" { nativeBuildInputs = [ profile ]; } ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME" project
      cd project
      clang --version | head -n 1 | grep -F 'version ${line}.'
      cc --version | head -n 1 | grep -F 'GCC'
      printf '#include <stdio.h>\nint main(void) { printf("%%d\\n", 40 + 2); return 0; }\n' > hello.c
      clang -o hello-c hello.c
      test "$(./hello-c)" = 42
      ${pkgs.patchelf}/bin/patchelf --print-rpath hello-c | grep -q ':/run/current-system/sw/lib$'
      printf '#include <iostream>\n#include <string>\nint main() { std::string text{"4"}; std::cout << text << 2 << std::endl; }\n' > hello.cpp
      clang++ -std=c++20 -o hello-cpp hello.cpp
      test "$(./hello-cpp)" = 42
      clang-format --version > /dev/null
      lldb --version > /dev/null
      touch "$out"
    '';
}
