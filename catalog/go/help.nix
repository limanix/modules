{ config, lib, ... }:
let
  metadata = builtins.fromTOML (builtins.readFile ./module.toml);
  selected = builtins.sort lib.versionOlder (lib.unique config.lmx.internal.go.versions);
  versions = map (line: config.lmx.internal.go.packages.${line}.go.version) selected;
in
{
  limanix.help.go = {
    title = "Go ${lib.concatStringsSep ", " versions}";
    summary = metadata.description;
    commands = [
      "go"
      "gofmt"
      "dlv"
      "gopls"
      "gcc"
    ]
    ++ map (line: "go-${line}") selected;
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
    guide = "https://limanix.dev/categories/nixos/modules/go/README.html";
  };
}
