local config = require("bullets.config")

local M = {}

local function parse_standard(line)
  local indent, marker, spacing, text = line:match("^(%s*)([-*+])(%s+)(.*)$")
  if not marker then
    return nil
  end

  return {
    indent = indent,
    marker = marker,
    spacing = spacing,
    text = text,
  }
end

local function at_eol(line)
  return vim.fn.col(".") == #line + 1
end

local function keys(lhs)
  return vim.api.nvim_replace_termcodes(lhs, true, false, true)
end

local function feed_cr()
  vim.api.nvim_feedkeys(keys("<CR>"), "in", false)
end

local function open_line_below()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { "" })
  vim.api.nvim_win_set_cursor(0, { lnum + 1, 0 })
  vim.cmd.startinsert()
end

local function insert_line(lnum, line)
  vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { line })
  vim.api.nvim_win_set_cursor(0, { lnum + 1, #line })
end

function M.insert_new_bullet()
  local mode = vim.fn.mode()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local bullet = parse_standard(line)

  if mode ~= "n" and not at_eol(line) then
    feed_cr()
    return ""
  end

  if not bullet then
    if mode == "n" then
      open_line_below()
      return ""
    end

    feed_cr()
    return ""
  end

  if bullet.text:match("^%s*$") and config.options.delete_last_bullet_if_empty == 1 then
    if mode ~= "n" then
      vim.api.nvim_feedkeys(keys("<Esc>ddi"), "n", false)
      return ""
    end

    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, {})
    vim.cmd.startinsert()
    return ""
  end

  local next_bullet = bullet.indent .. bullet.marker .. bullet.spacing

  if mode ~= "n" then
    insert_line(lnum, next_bullet)
    vim.cmd.startinsert({ bang = true })
    return ""
  end

  insert_line(lnum, next_bullet)
  vim.cmd.startinsert({ bang = true })

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
