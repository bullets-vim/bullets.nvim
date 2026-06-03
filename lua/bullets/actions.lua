local M = {}

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

function M.insert_new_bullet()
  if vim.fn.mode() == "n" then
    vim.cmd.startinsert({ bang = true })
  else
    feed("<CR>")
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
