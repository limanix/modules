{ pkgs }:
(pkgs.harlequin.override {
  withPostgresAdapter = true;
  withBigQueryAdapter = false;
}).overridePythonAttrs
  (previous: {
    postPatch = (previous.postPatch or "") + ''
      substituteInPlace src/harlequin/cli.py \
        --replace-fail 'DEFAULT_THEME = "harlequin"' 'DEFAULT_THEME = "catppuccin-mocha"'
    '';
  })
