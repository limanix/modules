# The global Nix configuration already supplies a complete interactive shell.
# Zsh runs its newuser script after /etc/zshenv and before personal startup files.
# Its script uses an existing handler before autoloading the setup wizard.
if [[ -o interactive && -o rcs ]] &&
   [[ ! -e "${ZDOTDIR:-$HOME}/.zshenv" &&
      ! -e "${ZDOTDIR:-$HOME}/.zprofile" &&
      ! -e "${ZDOTDIR:-$HOME}/.zshrc" &&
      ! -e "${ZDOTDIR:-$HOME}/.zlogin" ]] &&
   (( ! ${+functions[zsh-newuser-install]} )); then
  zsh-newuser-install() {
    # Keep the normal autoloadable wizard available for an explicit later run.
    unfunction zsh-newuser-install
  }
fi
