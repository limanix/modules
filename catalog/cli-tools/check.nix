{
  config,
  pkgs,
  hasPackage,
  ...
}:
config.programs.git.enable
&& builtins.all hasPackage [
  pkgs.ripgrep
  pkgs.fd
  pkgs.fzf
  pkgs.bat
  pkgs.eza
  pkgs.delta
  pkgs.jq
  pkgs.yq-go
  pkgs.xh
  pkgs.btop
  pkgs.dust
  pkgs.duf
  pkgs.tealdeer
]
&& builtins.any (
  settings:
  (settings.core.pager or null) == "${pkgs.delta}/bin/delta"
  && (settings.interactive.diffFilter or null) == "${pkgs.delta}/bin/delta --color-only"
) config.programs.git.config
