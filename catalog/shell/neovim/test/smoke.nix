{ pkgs, profile }:
pkgs.runCommand "neovim-headless-aliases"
  {
    nativeBuildInputs = [
      profile
      pkgs.coreutils
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    for editor in nvim vi vim; do
      export LMX_EDITOR_OUTPUT="$TMPDIR/$editor.txt"
      timeout --kill-after=5s 30 "$editor" --headless -u NONE -n \
        -c 'lua vim.api.nvim_buf_set_lines(0, 0, -1, false, { "LimaNix editor check" }); vim.cmd("write " .. vim.fn.fnameescape(vim.env.LMX_EDITOR_OUTPUT))' \
        -c 'qa!'
      test "$(cat "$LMX_EDITOR_OUTPUT")" = 'LimaNix editor check'
    done
    touch "$out"
  ''
