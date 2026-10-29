{
  evalSystem,
  pkgs,
  lib,
}:
let
  helpers = import ../../_shared/test/helpers.nix { inherit evalSystem pkgs lib; };
  inherit (helpers) evaluate profileFor;
  system = "/run/current-system/sw";
  patchelf = "${pkgs.patchelf}/bin/patchelf";
  native = evaluate [
    ./default.nix
    { environment.systemPackages = [ pkgs.openssl ]; }
  ];
  withGo = evaluate [
    ./versions/14.nix
    ../go/default.nix
  ];
  nativeLibraries =
    let
      profile = profileFor native;
      compiler = import ../../_shared/lib/compiler.nix {
        compiler = pkgs.gcc;
        prefix = "${profile}";
      };
      local =
        name:
        builtins.replaceStrings [ system ] [ "${profile}" ]
          native.config.environment.sessionVariables.${name};
    in
    pkgs.runCommandLocal "gcc-native-libraries" { nativeBuildInputs = [ profile ]; } ''
      export PATH="${compiler}/bin:$PATH" HOME="$TMPDIR/home" PKG_CONFIG_PATH='${local "PKG_CONFIG_PATH"}'
      export CMAKE_PREFIX_PATH='${local "CMAKE_PREFIX_PATH"}' ACLOCAL_PATH='${local "ACLOCAL_PATH"}'
      mkdir -p "$HOME" project
      cd project
      printf '#include <stdio.h>\n#include <openssl/ssl.h>\nint main(void) { if (!OPENSSL_init_ssl(0, NULL)) return 1; puts(OpenSSL_version(OPENSSL_VERSION)); return 0; }\n' > openssl.c
      cc -o with-pkg-config openssl.c $(pkg-config --cflags --libs openssl)
      ./with-pkg-config
      cc -o with-search-path openssl.c -lssl -lcrypto
      ./with-search-path
      printf 'cmake_minimum_required(VERSION 3.20)\nproject(native C)\nfind_package(OpenSSL REQUIRED)\nadd_executable(native openssl.c)\ntarget_link_libraries(native OpenSSL::SSL)\n' > CMakeLists.txt
      cmake -B build -G Ninja > /dev/null
      cmake --build build > /dev/null
      ./build/native
      printf 'AC_INIT([native], [1])\nAM_INIT_AUTOMAKE([foreign])\nAC_PROG_CC\nLT_INIT\nPKG_CHECK_MODULES([OPENSSL], [openssl])\nAC_CONFIG_FILES([Makefile])\nAC_OUTPUT\n' > configure.ac
      printf 'bin_PROGRAMS = native\nnative_SOURCES = openssl.c\nnative_CFLAGS = $(OPENSSL_CFLAGS)\nnative_LDADD = $(OPENSSL_LIBS)\n' > Makefile.am
      autoreconf -fi
      ./configure > /dev/null
      make > /dev/null
      ./native
      touch "$out"
    '';
  base = import ../../_shared/test/toolchain.nix {
    inherit evalSystem pkgs lib;
    spec = import ./toolchain.nix;
    coexisting = [
      "gcc"
      "bintools"
    ];
    profileCommands = tools: {
      gcc = "${tools.gcc}/bin/gcc";
      "g++" = "${tools.gcc}/bin/g++";
      cc = "${tools.gcc}/bin/cc";
      ld = "${tools.bintools}/bin/ld";
      clangd = "${tools.clangd}/bin/clangd";
    };
    commands =
      { line, profile, ... }:
      pkgs.runCommandLocal "gcc-${line}-commands-smoke" { nativeBuildInputs = [ profile ]; } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" project
        cd project
        gcc --version | head -n 1 | grep -F ' ${line}.'
        printf 'int answer(void) { return 42; }\n' > answer.c
        printf '#include <stdio.h>\nint answer(void);\nint main(void) { printf("%%d\\n", answer()); return 0; }\n' > hello.c
        cc -c answer.c
        ar rcs libanswer.a answer.o
        cc -o hello-c hello.c -L. -lanswer
        test "$(./hello-c)" = 42
        ${patchelf} --print-rpath hello-c | grep -q ':${system}/lib$'
        printf '#include <iostream>\n#include <string>\nint main() { std::string text{"4"}; std::cout << text << 2 << std::endl; }\n' > hello.cpp
        c++ -std=c++20 -o hello-cpp hello.cpp
        test "$(./hello-cpp)" = 42
        printf 'cmake_minimum_required(VERSION 3.20)\nproject(hello C)\nadd_library(answer STATIC answer.c)\nadd_executable(hello hello.c)\ntarget_link_libraries(hello answer)\n' > CMakeLists.txt
        cmake -B build -G Ninja > /dev/null
        cmake --build build > /dev/null
        test "$(./build/hello)" = 42
        gdb --version > /dev/null
        touch "$out"
      '';
  };
in
base
// {
  run = base.run // {
    inherit nativeLibraries;
    goPriority = pkgs.runCommandLocal "gcc-over-go-gcc" { } ''
      ${profileFor withGo}/bin/gcc --version | head -n 1 | grep -F ' 14.'
      touch "$out"
    '';
  };
}
