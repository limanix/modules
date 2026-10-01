{
  lib,
  pkgs,
  ...
}:
let
  carapaceInit =
    pkgs.runCommand "carapace-init.zsh"
      {
        nativeBuildInputs = [ pkgs.buildPackages.carapace ];
      }
      ''
        export XDG_CONFIG_HOME="$TMPDIR/config"
        export XDG_CACHE_HOME="$TMPDIR/cache"
        carapace _carapace zsh > "$out"
        # Resolve the shim directory for the VM user, not the Nix build user.
        substituteInPlace "$out" --replace-fail "$XDG_CONFIG_HOME" \
          ${lib.escapeShellArg "\${XDG_CONFIG_HOME:-$HOME/.config}"}
      '';
in
{
  limanix.user.shell = lib.mkDefault pkgs.zsh;

  environment.systemPackages = with pkgs; [
    carapace
    zsh-fzf-tab
  ];

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      # NixOS runs compinit before this hook. fzf-tab must precede widget wrappers.
      interactiveShellInit = lib.mkBefore ''
        source ${carapaceInit}
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' menu no
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
        # Leave Ctrl-R to Atuin regardless of integration order.
        FZF_CTRL_R_COMMAND=""
      '';
    };

    fzf.keybindings = true;

    starship = {
      enable = true;
      settings = {
        hostname.ssh_only = lib.mkDefault false;
        status.disabled = lib.mkDefault false;
      };
    };

    atuin = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        auto_sync = lib.mkDefault false;
        update_check = lib.mkDefault false;
      };
    };

    zoxide = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
