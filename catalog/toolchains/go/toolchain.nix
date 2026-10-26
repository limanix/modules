{
  name = "go";
  title = "Go";
  directory = ./.;
  main = "go";
  tool = "gopls";
  parsers.go = [
    "go"
    "gomod"
    "gosum"
  ];
  packages = import ./packages.nix;
  provider =
    { tools, ... }:
    {
      package = tools.gopls;
      command = "${tools.gopls}/bin/gopls";
      languages = [ "go" ];
    };
  systemPackages =
    {
      version,
      tools,
      pkgs,
      lib,
      priority,
    }:
    map (lib.setPrio priority) [
      tools.go
      tools.delve
    ]
    ++ [
      (pkgs.runCommandLocal "go-${version}-command" { } ''
        mkdir -p "$out/bin"
        ln -s "${tools.go}/bin/go" "$out/bin/go-${version}"
      '')
      pkgs.gcc
    ];
  commands = [
    "go"
    "gofmt"
    "dlv"
    "gopls"
    "gcc"
  ];
  versioned = line: [ "go-${line}" ];
  tips = [
    {
      label = "Build";
      text = "go build ./...";
    }
    {
      label = "Run tests";
      text = "go test ./...";
    }
    {
      label = "Race test";
      text = "go test -race ./...";
    }
  ];
  page = "inside/languages#go";
}
