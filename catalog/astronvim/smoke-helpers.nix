{ config, pkgs }:
let
  checkLua =
    script:
    "luafile ${pkgs.writeText "astronvim-run-check.lua" ''
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          vim.schedule(function()
            local ok, failure = pcall(function()
              assert(vim.v.vim_did_enter == 1, "smoke ran before VimEnter")
              dofile([[${script}]])
              assert(vim.v.errmsg == "", vim.v.errmsg)
            end)
            if not ok then
              vim.api.nvim_err_writeln(tostring(failure))
              vim.cmd("cquit 1")
            else
              vim.cmd("qa!")
            end
          end)
        end,
      })
    ''}";
  runEditor =
    name: editor: script:
    pkgs.runCommand name
      {
        nativeBuildInputs = [
          editor
          pkgs.coreutils
          pkgs.gnugrep
          config.programs.git.package
          pkgs.lazygit
        ];
      }
      ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$TMPDIR/config"
        export XDG_DATA_HOME="$TMPDIR/data"
        export XDG_STATE_HOME="$TMPDIR/state"
        export XDG_CACHE_HOME="$TMPDIR/cache"
        mkdir -p "$XDG_CONFIG_HOME/nvim" "$XDG_STATE_HOME"
        run_nvim() {
          if ! timeout 90 nvim --headless "$@" > "$TMPDIR/nvim.log" 2>&1; then
            cat "$TMPDIR/nvim.log"
            return 1
          fi
          cat "$TMPDIR/nvim.log"
          # Errors from exit autocmds do not reliably set Neovim's process status.
          if grep -E 'Error in|Error detected|Error executing|E[0-9]+:' "$TMPDIR/nvim.log"; then
            return 1
          fi
        }
        ${script}
        touch "$out"
      '';
in
{
  inherit checkLua runEditor;
}
