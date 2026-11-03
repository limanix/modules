{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Posting crashes on Textual's terminal themes, so the system theme draws the palette's colors.
  package = pkgs.posting.overridePythonAttrs (previous: {
    postPatch = (previous.postPatch or "") + ''
      cat >> src/posting/themes.py <<'EOF'

      BUILTIN_THEMES["limanix"] = TextualTheme(name="limanix", ${import ../../_shared/lib/textual.nix config.lmx.capabilities.theme})
      EOF
    '';
  });
in
{
  imports = [ ./help.nix ];

  environment.systemPackages = [ package ];
  environment.variables.POSTING_THEME = lib.mkDefault "limanix";
}
