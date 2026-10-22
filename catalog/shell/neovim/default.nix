{
  imports = [ ./help.nix ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };
}
