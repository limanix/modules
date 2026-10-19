{
  version,
  pinned,
  pkgs,
}:
let
  release = import ../_shared/lib/release.nix {
    releases = ./releases.nix;
    line = version;
    inherit pkgs pinned;
  };
  original = release.packages.${release.package};
  builder =
    if release ? buildSource then (release.resolve release.buildSource).packages else release.packages;
  # Reuse the application recipe and hashes with a separately pinned compiler.
  # Its upstream version test must also refer to this rebuilt package.
  k9s =
    if release ? buildSource then
      (original.override {
        inherit (builder)
          stdenv
          buildGoModule
          installShellFiles
          writableTmpDirAsHomeHook
          testers
          ;
        inherit k9s;
      }).overrideAttrs
        (previous: {
          # K9s fixtures use package-relative paths. Matching the build's path
          # mode lets every upstream test reuse compiled dependencies.
          checkFlags = (previous.checkFlags or [ ]) ++ [ "-trimpath" ];
        })
    else
      original;
  fingerprint = package: {
    inherit (package)
      version
      vendorHash
      proxyVendor
      tags
      ldflags
      doCheck
      ;
    sourcePath = package.src.outPath;
    sourceHash = package.src.outputHash;
    modulesPath = package.goModules.outPath;
    modulesHash = package.goModules.outputHash;
    inherit (package.meta) description license mainProgram;
  };
in
assert release.matches k9s.version;
assert !(release ? buildSource) || fingerprint k9s == fingerprint original;
{
  inherit k9s original;
  buildStdenv = builder.stdenv;
  buildGo = builder.go;
  unmodified =
    if release ? buildSource then
      original.override {
        inherit (builder)
          stdenv
          buildGoModule
          installShellFiles
          writableTmpDirAsHomeHook
          testers
          ;
        inherit k9s;
      }
    else
      original;
  inherit (release) endOfLife;
}
