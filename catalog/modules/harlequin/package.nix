{ pkgs, theme }:
(pkgs.harlequin.override {
  withPostgresAdapter = true;
  withBigQueryAdapter = false;
}).overridePythonAttrs
  (previous: {
    postPatch = (previous.postPatch or "") + ''
      substituteInPlace src/harlequin/cli.py \
        --replace-fail 'DEFAULT_THEME = "harlequin"' 'DEFAULT_THEME = "limanix"'
      substituteInPlace src/harlequin/app_base.py \
        --replace-fail 'from harlequin.colors import HARLEQUIN_TEXTUAL_THEME' \
          'from harlequin.colors import HARLEQUIN_TEXTUAL_THEME, LIMANIX_TEXTUAL_THEME' \
        --replace-fail 'self.register_theme(HARLEQUIN_TEXTUAL_THEME)' \
          $'self.register_theme(HARLEQUIN_TEXTUAL_THEME)\n        self.register_theme(LIMANIX_TEXTUAL_THEME)'
      cat >> src/harlequin/colors.py <<'EOF'

      LIMANIX_TEXTUAL_THEME = TextualTheme(name="limanix", ${import ../../_shared/lib/textual.nix theme})
      VALID_THEMES.update({"limanix": LIMANIX_TEXTUAL_THEME})
      EOF
    '';
  })
