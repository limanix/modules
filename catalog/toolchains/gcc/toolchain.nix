let
  profile = "/run/current-system/sw";
in
{
  name = "gcc";
  title = "GCC";
  directory = ./.;
  main = "gcc";
  tool = "clangd";
  priorityOffset = 1;
  parsers = {
    c = [ "c" ];
    cpp = [ "cpp" ];
    cmake = [ "cmake" ];
  };
  packages = import ./packages.nix;
  provider =
    { tools, ... }:
    {
      package = tools.clangd;
      command = "${tools.clangd}/bin/clangd";
      args = [ "--query-driver=${profile}/bin/*,/nix/store/*/bin/*" ];
      languages = [
        "c"
        "cpp"
      ];
    };
  systemPackages =
    {
      tools,
      lib,
      priority,
      ...
    }:
    map (lib.setPrio priority) [
      tools.gcc
      tools.bintools
    ];
  extra =
    { pkgs, ... }:
    {
      environment = {
        systemPackages = with pkgs; [
          gdb
          gnumake
          cmake
          ninja
          meson
          pkg-config
          autoconf
          automake
          libtool
          gnum4
        ];
        extraOutputsToInstall = [ "dev" ];
        pathsToLink = [
          "/include"
          "/share/aclocal"
          "/share/cmake"
          "/share/pkgconfig"
        ];
        sessionVariables = {
          PKG_CONFIG_PATH = "${profile}/lib/pkgconfig:${profile}/share/pkgconfig";
          CMAKE_PREFIX_PATH = profile;
          ACLOCAL_PATH = "${profile}/share/aclocal";
        };
      };
    };
  commands = [
    "gcc"
    "g++"
    "cc"
    "c++"
    "gdb"
    "make"
    "cmake"
    "ninja"
    "meson"
    "pkg-config"
    "clangd"
  ];
  tips = [
    {
      label = "Compile";
      text = "cc -o hello hello.c";
    }
    {
      label = "CMake";
      text = "cmake -B build -G Ninja && cmake --build build";
    }
    {
      label = "Library";
      text = "Add it to [nixos] packages; the compiler and pkg-config find it.";
    }
  ];
  page = "modules/gcc";
}
