local config = require("bullets.config")
local ordinal = require("bullets.ordinal")

local M = {}

local function style_enabled(marker)
  for _, style in ipairs(config.options.list_item_styles) do
    if style == marker then
      return true
    end

    if style:sub(-1) == "+" and marker:match("^" .. vim.pesc(style:sub(1, -2)) .. "+$") then
      return true
    end
  end

  return false
end

local function parse_static(line)
  local indent, marker, spacing, text = line:match("^(%s*)(\\item)(%s+)(.*)$")
  if not marker then
    indent, marker, spacing, text = line:match("^(%s*)(#%.)(%s+)(.*)$")
  end
  if not marker then
    indent, marker, spacing, text = line:match("^(%s*)([%*.]+)(%s+)(.*)$")
    if marker and (marker == "*" or not (marker:match("^%*+$") or marker:match("^%.+$"))) then
      marker = nil
    end
  end
  if not marker or not style_enabled(marker) then
    return nil
  end

  return {
    type = "static",
    indent = indent,
    marker = marker,
    spacing = spacing,
    text = text,
  }
end

local function parse_standard(line)
  local indent, marker, spacing, text = line:match("^(%s*)([-*+])(%s+)(.*)$")
  if not marker then
    return nil
  end
  if not style_enabled(marker) then
    return nil
  end

  return {
    indent = indent,
    marker = marker,
    spacing = spacing,
    text = text,
  }
end

local function parse_numeric(line)
  local indent, marker, closure, spacing, text = line:match("^(%s*)(%d+)([.)])(%s+)(.*)$")
  if not marker then
    return nil
  end

  return {
    type = "num",
    indent = indent,
    marker = marker,
    closure = closure,
    spacing = spacing,
    text = text,
  }
end

local function parse_alpha(line)
  local max = config.options.max_alpha_characters
  if max == 0 then
    return nil
  end

  local indent, marker, closure, spacing, text = line:match("^(%s*)(%a+)([.)])(%s+)(.*)$")
  if not marker or #marker > max or not (marker == marker:lower() or marker == marker:upper()) then
    return nil
  end

  return {
    type = "abc",
    indent = indent,
    marker = marker,
    closure = closure,
    spacing = spacing,
    text = text,
  }
end

local function parse_roman(line)
  if not config.options.enable_roman_list then
    return nil
  end

  local indent, marker, closure, spacing, text = line:match("^(%s*)(%a+)([.)])(%s+)(.*)$")
  if not marker or not (marker == marker:lower() or marker == marker:upper()) or not ordinal.is_roman(marker) then
    return nil
  end

  return {
    type = "rom",
    indent = indent,
    marker = marker,
    closure = closure,
    spacing = spacing,
    text = text,
  }
end

local function parse_line(line)
  local static = parse_static(line)
  if static then
    return { static }
  end

  local standard = parse_standard(line)
  if standard then
    standard.type = "std"
    return { standard }
  end

  local numeric = parse_numeric(line)
  if numeric then
    return { numeric }
  end

  local alpha = parse_alpha(line)
  local roman = parse_roman(line)

  return vim.tbl_filter(function(item)
    return item ~= nil
  end, { alpha, roman })
end

local resolve_bullet

local function previous_ordered_type(lnum, indent)
  for row = lnum - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if line == "" then
      return nil
    end

    local bullet = resolve_bullet(parse_line(line), row)
    if bullet and bullet.indent == indent and (bullet.type == "abc" or bullet.type == "rom") then
      return bullet.type
    end
  end

  return nil
end

function resolve_bullet(bullets, lnum)
  if #bullets == 0 then
    return nil
  end
  if #bullets == 1 then
    return bullets[1]
  end

  local previous_type = previous_ordered_type(lnum, bullets[1].indent)
  if previous_type then
    for _, bullet in ipairs(bullets) do
      if bullet.type == previous_type then
        return bullet
      end
    end
  end

  for _, bullet in ipairs(bullets) do
    if bullet.type == "rom" then
      return bullet
    end
  end

  return bullets[1]
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

local function split_line()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum, col = cursor[1], cursor[2]
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 1)

  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { before, after })
  vim.api.nvim_win_set_cursor(0, { lnum + 1, 0 })
  vim.cmd.startinsert()
end

local function insert_line(lnum, line)
  vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { line })
  vim.api.nvim_win_set_cursor(0, { lnum + 1, #line })
end

local function pad_right(prefix, width)
  if not config.options.pad_right or #prefix >= width then
    return prefix
  end

  return prefix .. string.rep(" ", width - #prefix)
end

local function next_marker(bullet)
  if bullet.type == "num" then
    return tostring(tonumber(bullet.marker) + 1)
  end
  if bullet.type == "abc" then
    local marker =
      ordinal.number_to_abc(ordinal.abc_to_number(bullet.marker) + 1, bullet.marker == bullet.marker:lower())
    if #marker > config.options.max_alpha_characters then
      return nil
    end
    return marker
  end
  if bullet.type == "rom" then
    return ordinal.number_to_roman(ordinal.roman_to_number(bullet.marker) + 1, bullet.marker == bullet.marker:lower())
  end

  return bullet.marker
end

local function prefix_width(bullet)
  if bullet.type == "num" or bullet.type == "abc" or bullet.type == "rom" then
    return #bullet.indent + #bullet.marker + #bullet.closure + #bullet.spacing
  end

  return #bullet.indent + #bullet.marker + #bullet.spacing
end

local function next_prefix(bullet)
  local marker = next_marker(bullet)
  if not marker then
    return nil
  end

  if bullet.type == "std" then
    return bullet.indent .. marker .. bullet.spacing
  end
  if bullet.type == "static" then
    return bullet.indent .. marker .. bullet.spacing
  end

  local prefix = marker .. bullet.closure .. " "
  return bullet.indent .. pad_right(prefix, #bullet.marker + #bullet.closure + #bullet.spacing)
end

local function wrapped_owner(lnum, line)
  if not config.options.enable_wrapped_lines or line:match("^%s*$") then
    return nil
  end

  local current_indent = #(line:match("^%s*") or "")
  for row = lnum - 1, 1, -1 do
    local previous_line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if previous_line:match("^%s*$") then
      return nil
    end

    local previous_bullet = resolve_bullet(parse_line(previous_line), row)
    if previous_bullet and current_indent >= prefix_width(previous_bullet) then
      return previous_bullet
    end
  end

  return nil
end

function M.insert_new_bullet()
  local mode = vim.fn.mode()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local bullet = resolve_bullet(parse_line(line), lnum) or wrapped_owner(lnum, line)

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

  local prefix = next_prefix(bullet)
  if not prefix then
    if mode == "n" then
      open_line_below()
      return ""
    end

    feed_cr()
    return ""
  end

  if mode ~= "n" then
    insert_line(lnum, prefix)
    vim.cmd.startinsert({ bang = true })
    return ""
  end

  insert_line(lnum, prefix)
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
