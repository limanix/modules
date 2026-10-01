{
  pkgs,
  lib,
  version,
  parsers ? [ ],
}:
let
  release = (import ./releases.nix).${version};
  source = builtins.fetchTarball {
    url = "https://codeload.github.com/AstroNvim/AstroNvim/tar.gz/refs/tags/v${release.version}";
    inherit (release) sha256;
  };
  astro = pkgs.vimUtils.buildVimPlugin {
    pname = "AstroNvim";
    inherit (release) version;
    src = source;
    # AstroNvim modules are initialized together by lazy.nvim, not individually.
    doCheck = false;
  };
  # These pinned upstream declarations are literal Lua tables, not executable configuration.
  quotedStrings =
    text: map builtins.head (builtins.filter builtins.isList (builtins.split ''"([^"]*)"'' text));
  snapshotLines = builtins.filter (
    line:
    !builtins.elem line [
      ""
      "return {"
      "}"
    ]
  ) (lib.splitString "\n" (builtins.readFile "${source}/lua/astronvim/lazy_snapshot.lua"));
  repositories = map (
    line:
    let
      entry = builtins.match ''[[:space:]]*[{] "([^"]+/[^"]+)", .*[}],[[:space:]]*'' line;
    in
    if entry == null then throw "AstroNvim changed its plugin snapshot format" else builtins.head entry
  ) snapshotLines;
  parserDeclarations = builtins.filter (
    line: builtins.match "[[:space:]]*ensure_installed = [{].*[}],[[:space:]]*" line != null
  ) (lib.splitString "\n" (builtins.readFile "${source}/lua/astronvim/plugins/_astrocore.lua"));
  parserNames =
    assert lib.assertMsg (
      builtins.length parserDeclarations == 1
    ) "AstroNvim changed its default Tree-sitter parser declaration";
    lib.unique (quotedStrings (builtins.head parserDeclarations) ++ parsers);
  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
    available:
    map (name: available.${name} or (throw "AstroNvim: unknown Tree-sitter parser ${name}")) parserNames
  );
  withDependencies =
    plugin: [ plugin ] ++ lib.concatMap withDependencies (plugin.dependencies or [ ]);
  pluginName =
    repository: lib.toLower (lib.replaceStrings [ "." ] [ "-" ] (builtins.baseNameOf repository));
  pluginFor =
    repository:
    let
      name = pluginName repository;
      package =
        pkgs.vimPlugins.${name} or (throw "AstroNvim plugin ${repository} has no nixpkgs package ${name}");
      homepage = lib.toLower (lib.removeSuffix "/" (package.meta.homepage or ""));
    in
    assert lib.assertMsg (lib.hasSuffix "/${lib.toLower repository}" homepage)
      "AstroNvim plugin ${repository} does not match nixpkgs package ${name}";
    if name == "nvim-treesitter" then treesitter else package;
in
assert lib.assertMsg (repositories != [ ]) "AstroNvim plugin snapshot is empty";
assert lib.assertMsg (
  builtins.length repositories == builtins.length (lib.unique (map pluginName repositories))
) "AstroNvim plugin names do not map uniquely to nixpkgs";
{
  inherit astro treesitter parserNames;
  inherit (release) endOfLife;
  parserDirectory = pkgs.symlinkJoin {
    name = "astronvim-parsers";
    paths = lib.unique (lib.concatMap withDependencies treesitter.dependencies);
  };
  plugins = lib.genAttrs repositories pluginFor;
}
