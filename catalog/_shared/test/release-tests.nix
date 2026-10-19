{ lib }:
let
  unstable = builtins.fromTOML (builtins.readFile ../unstable.toml);
  snapshot = "0123456789abcdef0123456789abcdef01234567";
  compiler = "89abcdef0123456789abcdef0123456789abcdef";
  base = {
    inherit lib;
    tool.version = "1.9.4";
  };
  pinned = {
    ${unstable.rev}.tool.version = "1.10.3";
    ${snapshot}.tool.version = "2.0.1";
    ${compiler}.marker = "compiler";
  };
  resolver =
    packageSets: line:
    import ../lib/release.nix {
      releases = ./fixtures/release/releases.nix;
      inherit line;
      pkgs = base;
      pinned = packageSets;
    };
  resolve = resolver pinned;
  lazy = resolver (throw "Resolving pins evaluated a package set");
  rejects = line: !(builtins.tryEval (resolve line)).success;
  older = resolve "1.9";
  newer = resolve "1.10";
  frozen = resolve "2";
in
{
  unstableRevision =
    builtins.attrNames unstable == [
      "rev"
      "sha256"
    ]
    && builtins.match "[0-9a-f]{40}" unstable.rev != null
    && builtins.match "sha256-[A-Za-z0-9+/]{43}=" unstable.sha256 != null;
  releaseBase =
    older.packages.tool.version == "1.9.4"
    && older.pins == { }
    && older.endOfLife
    && older.matches "1.9.4"
    && !(older.matches "1.90.1")
    && !(older.matches "1.10.0");
  releaseUnstable =
    newer.packages.tool.version == "1.10.3"
    && newer.pins == { ${unstable.rev} = unstable.sha256; }
    && newer.matches "1.10.3"
    && !(newer.matches "1.11.0");
  releaseSnapshot =
    frozen.packages.tool.version == "2.0.1"
    && frozen.pins == { ${snapshot} = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; }
    && frozen.matches "2.0.1"
    && !(frozen.matches "2.0.2");
  releaseFieldSources =
    (frozen.resolve frozen.buildSource).packages.marker == "compiler"
    &&
      (frozen.resolve frozen.buildSource).pins == {
        ${compiler} = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
      };
  releaseLazyPins =
    (lazy "1.9").pins == { }
    && (lazy "1.10").pins == { ${unstable.rev} = unstable.sha256; }
    && (lazy "2").pins == { ${snapshot} = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; };
  releaseRejects = builtins.all rejects [
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
  ];
}
