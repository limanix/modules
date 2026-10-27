{
  version,
  pinned,
  pkgs,
}:
let
  release = import ../../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  inherit (release) packages;
  python = packages.${release.package};
  interpreter = "python${python.pythonVersion}";
  runtime = packages.symlinkJoin {
    name = "${python.name}-runtime";
    inherit (python) version;
    paths = [ python ];
    nativeBuildInputs = [ packages.patchelf ];
    postBuild = ''
      rm "$out/bin/${interpreter}"
      install -m 755 ${python}/bin/${interpreter} "$out/bin/${interpreter}"
      patchelf --add-needed libstdc++.so.6 --add-needed libz.so.1 \
        --set-rpath "${
          packages.lib.makeLibraryPath [
            packages.gcc_latest.cc.lib
            packages.zlib
          ]
        }:$(patchelf --print-rpath "$out/bin/${interpreter}")" \
        "$out/bin/${interpreter}"
      ln -sf ${interpreter} "$out/bin/python3"
      ln -sf ${interpreter} "$out/bin/python"
    '';
  };
in
assert release.matches python.version;
{
  inherit python runtime;
  virtualenv = pkgs.writeShellScriptBin "virtualenv" ''
    export VIRTUALENV_PYTHON="''${VIRTUALENV_PYTHON:-${runtime}/bin/${interpreter}}"
    exec ${packages.virtualenv}/bin/virtualenv "$@"
  '';
  inherit (release) endOfLife;
}
