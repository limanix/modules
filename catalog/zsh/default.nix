{
  config,
  lib,
  pkgs,
  ...
}:
let
  carapaceInit =
    pkgs.runCommandLocal "carapace-init.zsh"
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
      shellInit = builtins.readFile ./first-run.zsh;
      enableCompletion = true;
      # Oh My Zsh initializes completion after adding its functions and plugins.
      enableGlobalCompInit = false;
      ohMyZsh = {
        enable = true;
        preLoaded = ''
          # Leave Ctrl-R to Atuin when the Oh My Zsh fzf plugin loads.
          FZF_CTRL_R_COMMAND=""
        '';
      };
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      # Run after Oh My Zsh's compinit and before highlighting (order 1500).
      # Autosuggestions wraps widgets at the first precmd, after this hook.
      interactiveShellInit = lib.mkOrder 1100 ''
        source ${carapaceInit}
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' menu no
        zstyle ':completion:*:*:*:*:*' menu no
        # fzf-tab must capture Zsh completion, not Oh My Zsh's fzf-completion.
        bindkey '^I' expand-or-complete
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '';
    };

    fzf.keybindings = true;

    starship = {
      enable = true;
      settings =
        lib.recursiveUpdate
          (import ./prompt.nix {
            inherit lib;
            inherit (config.lmx.capabilities) theme;
          })
          {
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
