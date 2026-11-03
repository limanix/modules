{ config, lib, ... }:
let
  inherit (config.lmx.capabilities) theme;
  inherit (theme) palette;
  color = role: "fg=${palette.${role}}";
in
lib.mkIf (theme.name != "system") {
  programs.zsh = {
    autosuggestions.highlightStyle = lib.mkDefault (color "muted");
    syntaxHighlighting.styles = lib.mapAttrs (_: lib.mkDefault) {
      unknown-token = "${color "red"},bold";
      reserved-word = color "purple";
      alias = color "green";
      suffix-alias = "${color "green"},underline";
      global-alias = color "cyan";
      builtin = color "green";
      function = color "green";
      command = color "green";
      precommand = "${color "green"},underline";
      hashed-command = color "green";
      autodirectory = "${color "green"},underline";
      globbing = color "blue";
      history-expansion = color "blue";
      command-substitution-delimiter = color "purple";
      process-substitution-delimiter = color "purple";
      back-quoted-argument-delimiter = color "purple";
      single-quoted-argument = color "yellow";
      double-quoted-argument = color "yellow";
      dollar-quoted-argument = color "yellow";
      rc-quote = color "cyan";
      dollar-double-quoted-argument = color "cyan";
      back-double-quoted-argument = color "cyan";
      back-dollar-quoted-argument = color "cyan";
      redirection = color "yellow";
      comment = color "muted";
      arg0 = color "green";
    };
  };

  programs.atuin.settings.theme.name = lib.mkDefault "limanix";
  environment.etc."atuin/themes/limanix.toml".text = ''
    [theme]
    name = "limanix"

    [colors]
    AlertInfo = "${palette.green}"
    AlertWarn = "${palette.yellow}"
    AlertError = "${palette.red}"
    Annotation = "${palette.blue}"
    Base = "${palette.foreground}"
    Guidance = "${palette.subtle}"
    Important = "${palette.accent}"
    Title = "${palette.accent}"
    Muted = "${palette.muted}"
  '';
}
