let
  profile = "/run/current-system/sw";
in
{
  name = "clang";
  title = "Clang";
  directory = ./.;
  main = "clang";
  tool = "clangd";
  priorityOffset = -3;
  providerPriority = 900;
  parsers = {
    c = [ "c" ];
    cpp = [ "cpp" ];
  };
  packages = import ./packages.nix;
  provider =
    { tools, ... }:
    {
      package = tools.clang-tools;
      command = "${tools.clang-tools}/bin/clangd";
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
      tools.clang
      tools.lldb
      tools.clang-tools
    ];
  commands = [
    "clang"
    "clang++"
    "lldb"
    "clang-format"
    "clang-tidy"
    "clangd"
  ];
  tips = [
    {
      label = "Compile";
      text = "clang++ -std=c++23 -o app main.cpp";
    }
    {
      label = "CMake";
      text = "CC=clang CXX=clang++ cmake -B build -G Ninja";
    }
    {
      label = "Format";
      text = "clang-format -i main.cpp";
    }
  ];
  page = "modules/clang";
}
