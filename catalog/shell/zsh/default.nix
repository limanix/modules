{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lmx.zsh) prompt;
  inherit (config.lmx.capabilities) theme;
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
  imports = [ ./help.nix ];

  options.lmx.zsh.prompt = lib.mkOption {
    type = lib.types.enum [
      "pure"
      "starship"
      "none"
    ];
    default = "pure";
    description = ''
      Prompt of Zsh: Pure, Starship, or none, which leaves the prompt to personal startup files.
      Pure and Starship use the colors of the guest's theme, the terminal's own with the system
      flavor, and, outside tmux, show the words of `lmx status --short`.
    '';
  };

  config = {
    limanix.user.shell = lib.mkDefault pkgs.zsh;

    environment.systemPackages =
      with pkgs;
      [
        carapace
        zsh-fzf-tab
      ]
      ++ lib.optional (prompt == "pure") pure-prompt;

    programs = {
      zsh = {
        enable = true;
        shellInit = builtins.readFile ./first-run.zsh + ''
          if [[ ''${ATUIN_CONFIG_DIR-} == /etc/atuin && -e ''${XDG_CONFIG_HOME:-$HOME/.config}/atuin/config.toml ]]; then
            unset ATUIN_CONFIG_DIR
          fi
        '';
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

        # Starship sets its own prompt initialization; none leaves the prompt to ~/.zshrc.
        promptInit = lib.mkIf (prompt != "starship") (
          lib.mkDefault (
            if prompt == "pure" then
              import ./pure.nix {
                inherit lib theme;
                pure = pkgs.pure-prompt;
              }
            else
              ""
          )
        );
      };

      fzf.keybindings = true;

      starship = {
        enable = prompt == "starship";
        settings =
          lib.recursiveUpdate
            (import ./starship.nix {
              inherit lib theme;
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
  };
}
