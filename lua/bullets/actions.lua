local M = {}

function M.insert_new_bullet()
  if vim.fn.mode() == "n" then
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { "" })
    vim.api.nvim_win_set_cursor(0, { lnum + 1, 0 })
    vim.cmd.startinsert()
  else
    return "\r"
  end

  return ""
end

function M.renumber_list() end

function M.renumber_selection() end

function M.toggle_checkbox() end

function M.recompute_checkboxes() end

function M.demote() end

function M.promote() end

function M.demote_visual() end

function M.promote_visual() end

function M.select_checkbox() end

function M.select_checkbox_inside() end

function M.select_bullet() end

function M.select_bullet_text() end

return M
