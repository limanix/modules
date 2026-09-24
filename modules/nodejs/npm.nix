{
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs,
  version,
  hash,
}:
stdenvNoCC.mkDerivation {
  pname = "npm";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/npm/-/npm-${version}.tgz";
    inherit hash;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/node_modules/npm" "$out/bin" "$out/share/bash-completion/completions"
    cp -r . "$out/lib/node_modules/npm"

    for command in npm npx; do
      makeWrapper "${nodejs}/bin/node" "$out/bin/$command" \
        --add-flags "$out/lib/node_modules/npm/bin/$command-cli.js" \
        --prefix PATH : "${nodejs}/bin"
    done

    cp -r man "$out/share/man"
    ln -s "$out/lib/node_modules/npm/lib/utils/completion.sh" "$out/share/bash-completion/completions/npm"

    runHook postInstall
  '';
}
