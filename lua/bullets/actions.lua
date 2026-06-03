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

local function insert_lines(lnum, lines, cursor_index)
  vim.api.nvim_buf_set_lines(0, lnum, lnum, false, lines)
  local line = lines[cursor_index]
  vim.api.nvim_win_set_cursor(0, { lnum + cursor_index, #line })
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

local current_prefix

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

function current_prefix(bullet)
  if bullet.type == "std" or bullet.type == "static" then
    return bullet.indent .. bullet.marker .. bullet.spacing
  end

  local prefix = bullet.marker .. bullet.closure .. " "
  return bullet.indent .. pad_right(prefix, #bullet.marker + #bullet.closure + #bullet.spacing)
end

local function checkbox_markers()
  local markers = {}
  local configured = config.options.checkbox_markers or ""

  for index = 0, vim.fn.strchars(configured) - 1 do
    table.insert(markers, vim.fn.strcharpart(configured, index, 1))
  end

  return markers
end

local function checkbox_marker_index(marker, markers)
  for index, configured in ipairs(markers) do
    if marker == configured then
      return index
    end
  end

  if marker == " " then
    return 1
  end

  local checked = markers[#markers]
  if checked and (marker:lower() == checked:lower() or marker:lower() == "x") then
    return #markers
  end

  return nil
end

local function parse_checkbox_text(text)
  local marker, spacing, rest = text:match("^%[([^%]]+)%](%s*)(.*)$")
  if not marker then
    return nil
  end

  local markers = checkbox_markers()
  local index = checkbox_marker_index(marker, markers)
  if not index then
    return nil
  end

  return {
    marker = marker,
    spacing = spacing,
    rest = rest,
    index = index,
    markers = markers,
  }
end

local function checkbox_unchecked_marker()
  return checkbox_markers()[1]
end

local function checkbox_checked_marker(markers)
  return markers[#markers]
end

local function checkbox_state(checkbox)
  if checkbox.index == 1 then
    return "unchecked"
  end
  if checkbox.index == #checkbox.markers then
    return "checked"
  end

  return "partial"
end

local function checkbox_text(marker, checkbox)
  return "[" .. marker .. "]" .. checkbox.spacing .. checkbox.rest
end

local function set_checkbox_marker(lnum, bullet, checkbox, marker)
  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { current_prefix(bullet) .. checkbox_text(marker, checkbox) })
end

local function checkbox_continuation_prefix(bullet, prefix)
  local checkbox = parse_checkbox_text(bullet.text)
  local unchecked = checkbox and checkbox_unchecked_marker()
  if not unchecked then
    return prefix
  end

  return prefix .. "[" .. unchecked .. "]" .. checkbox.spacing
end

local function is_empty_bullet_text(text)
  if text == "" then
    return true
  end

  local checkbox = parse_checkbox_text(text)
  return checkbox and checkbox.rest == ""
end

local function indent_unit()
  if not vim.o.expandtab and vim.o.shiftwidth ~= 8 then
    return "\t"
  end

  return string.rep(" ", vim.o.shiftwidth > 0 and vim.o.shiftwidth ~= 8 and vim.o.shiftwidth or 2)
end

local function style_for_bullet(bullet)
  if bullet.type == "std" then
    return "std" .. bullet.marker
  end
  if bullet.type == "static" then
    return bullet.marker
  end
  if bullet.type == "num" then
    return "num"
  end
  if bullet.type == "abc" then
    return bullet.marker == bullet.marker:lower() and "abc" or "ABC"
  end
  if bullet.type == "rom" then
    return bullet.marker == bullet.marker:lower() and "rom" or "ROM"
  end

  return nil
end

local function bullet_for_style(style, indent)
  if style == "num" then
    return { type = "num", indent = indent, marker = "1", closure = ".", spacing = " ", text = "" }
  end
  if style == "abc" then
    return { type = "abc", indent = indent, marker = "a", closure = ".", spacing = " ", text = "" }
  end
  if style == "ABC" then
    return { type = "abc", indent = indent, marker = "A", closure = ".", spacing = " ", text = "" }
  end
  if style == "rom" then
    return { type = "rom", indent = indent, marker = "i", closure = ".", spacing = " ", text = "" }
  end
  if style == "ROM" then
    return { type = "rom", indent = indent, marker = "I", closure = ".", spacing = " ", text = "" }
  end

  local marker = style:match("^std(.+)$")
  if marker then
    return { type = "std", indent = indent, marker = marker, spacing = " ", text = "" }
  end

  return nil
end

local function child_bullet(bullet)
  local current_style = style_for_bullet(bullet)
  if not current_style then
    return nil
  end

  for index, style in ipairs(config.options.outline_levels) do
    if style == current_style then
      local next_style = config.options.outline_levels[index + 1]
      return next_style and bullet_for_style(next_style, bullet.indent .. indent_unit()) or nil
    end
  end

  return nil
end

local function outline_index(style)
  for index, outline_style in ipairs(config.options.outline_levels) do
    if outline_style == style then
      return index
    end
  end

  return nil
end

local function indent_depth(indent)
  local unit = indent_unit()
  local depth = 0

  while indent:sub(1, #unit) == unit do
    depth = depth + 1
    indent = indent:sub(#unit + 1)
  end

  return depth
end

local function parent_indent(indent)
  local unit = indent_unit()
  if indent:sub(-#unit) == unit then
    return indent:sub(1, -#unit - 1)
  end

  return indent
    :gsub("\t$", "")
    :gsub(string.rep(" ", vim.o.shiftwidth > 0 and vim.o.shiftwidth or vim.o.tabstop) .. "$", "")
end

local function first_bullet_for_style(style, indent)
  return bullet_for_style(style, indent)
end

local function previous_bullet_with_style(lnum, style, indent)
  for row = lnum - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if line == "" then
      return nil
    end

    local bullet = resolve_bullet(parse_line(line), row)
    if bullet and bullet.indent == indent and style_for_bullet(bullet) == style then
      return bullet
    end
  end

  return nil
end

local function bullet_for_level(style, indent, lnum)
  local bullet = first_bullet_for_style(style, indent)
  if not bullet then
    return nil
  end

  local previous = previous_bullet_with_style(lnum, style, indent)
  if previous then
    local marker = next_marker(previous)
    if marker then
      bullet.marker = marker
    end
  end

  return bullet
end

local function fallback_style_for_indent(indent)
  return config.options.outline_levels[indent_depth(indent) + 1]
end

local function change_line_level(lnum, direction)
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
  local bullet = resolve_bullet(parse_line(line), lnum)
  if not bullet then
    return false
  end

  local style = style_for_bullet(bullet)
  local index = style and outline_index(style) or nil
  local next_style
  local next_indent

  if direction == "demote" then
    next_style = index and config.options.outline_levels[index + 1]
      or fallback_style_for_indent(bullet.indent .. indent_unit())
    next_indent = bullet.indent .. indent_unit()

    if not next_style then
      local last_style = config.options.outline_levels[#config.options.outline_levels]
      if last_style and last_style:match("^std") and bullet.type == "std" then
        next_style = style
      else
        return false
      end
    end
  else
    if bullet.indent == "" then
      vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { bullet.text })
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      return true
    end

    next_indent = parent_indent(bullet.indent)
    next_style = index and config.options.outline_levels[index - 1] or fallback_style_for_indent(next_indent)
    if not next_style then
      return false
    end
  end

  local next_bullet = bullet_for_level(next_style, next_indent, lnum)
  if not next_bullet then
    return false
  end

  local checkbox = parse_checkbox_text(bullet.text)
  if checkbox then
    next_bullet.marker = bullet.marker
    next_bullet.type = bullet.type
    next_bullet.closure = bullet.closure
    next_bullet.spacing = bullet.spacing
  end

  local prefix = current_prefix(next_bullet)
  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { prefix .. bullet.text })
  if checkbox then
    prefix = prefix .. "[" .. checkbox.marker .. "]" .. checkbox.spacing
  end
  vim.api.nvim_win_set_cursor(0, { lnum, #prefix })
  return true
end

local function change_current_line_level(direction)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local changed = change_line_level(lnum, direction)
  if changed and config.options.renumber_on_change then
    M.renumber_list()
  end
  return changed
end

local function visual_range(first, last)
  if first and last then
    return first, last
  end

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  return math.min(start_pos[2], end_pos[2]), math.max(start_pos[2], end_pos[2])
end

local function change_visual_level(direction, first, last)
  first, last = visual_range(first, last)
  local changed = false
  for lnum = first, last do
    changed = change_line_level(lnum, direction) or changed
  end
  if changed and config.options.renumber_on_change then
    M.renumber_selection()
  end
  return changed
end

local function ends_with_colon(text)
  return text:sub(-1) == ":" or text:sub(-3) == "："
end

local function spaced_lines(prefix)
  local lines = {}
  for _ = 2, config.options.line_spacing do
    table.insert(lines, "")
  end
  table.insert(lines, prefix)
  return lines, #lines
end

local function previous_bullet_with_indent(lnum, indent)
  for row = lnum - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if line:match("^%s*$") then
      return nil
    end

    local previous = resolve_bullet(parse_line(line), row)
    if previous and previous.indent == indent then
      return previous
    end
  end

  return nil
end

local function previous_parent_bullet(lnum, indent)
  for row = lnum - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if line:match("^%s*$") then
      return nil
    end

    local previous = resolve_bullet(parse_line(line), row)
    if previous and #previous.indent < #indent and indent:sub(1, #previous.indent) == previous.indent then
      return previous
    end
  end

  return nil
end

local function delete_empty_bullet(lnum, bullet, mode)
  local behavior = config.options.delete_last_bullet_if_empty
  if behavior == 0 then
    if mode == "n" then
      open_line_below()
    else
      split_line()
    end
    return true
  end

  if behavior == 2 and bullet.indent ~= "" then
    local parent = previous_parent_bullet(lnum, bullet.indent)
    local prefix = parent and next_prefix(parent) or ""
    if prefix then
      prefix = checkbox_continuation_prefix(bullet, prefix)
    end
    vim.api.nvim_set_current_line(prefix or "")
    vim.api.nvim_win_set_cursor(0, { lnum, #(prefix or "") })
    return true
  end

  vim.api.nvim_set_current_line(bullet.indent)
  vim.api.nvim_win_set_cursor(0, { lnum, #bullet.indent })
  return true
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
    if not previous_bullet and #(previous_line:match("^%s*") or "") < current_indent then
      return nil
    end
  end

  return nil
end

local function is_ordered(bullet)
  return bullet.type == "num" or bullet.type == "abc" or bullet.type == "rom"
end

local function marker_number(bullet)
  if bullet.type == "num" then
    return tonumber(bullet.marker)
  end
  if bullet.type == "abc" then
    return ordinal.abc_to_number(bullet.marker)
  end
  if bullet.type == "rom" then
    return ordinal.roman_to_number(bullet.marker)
  end

  return nil
end

local function number_marker(type, value, lower)
  if type == "num" then
    return tostring(value)
  end
  if type == "abc" then
    return ordinal.number_to_abc(value, lower)
  end
  if type == "rom" then
    return ordinal.number_to_roman(value, lower)
  end

  return nil
end

local function bullet_at(lnum)
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
  if not line then
    return nil, nil
  end

  return resolve_bullet(parse_line(line), lnum), line
end

local function boundary_bullet_at(lnum)
  local bullet, line = bullet_at(lnum)
  if bullet then
    return bullet, line
  end

  return wrapped_owner(lnum, line or ""), line
end

local function line_indent(lnum)
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
  return #(line:match("^%s*") or "")
end

local function first_bullet_line(lnum, min_indent)
  min_indent = min_indent or 0
  if min_indent < 0 then
    return -1
  end

  local first = lnum
  local row = lnum - 1
  local blank_lines = 0
  while row >= 1 do
    local bullet, line = boundary_bullet_at(row)
    if bullet and #bullet.indent >= min_indent then
      first = row
      blank_lines = 0
    elseif line and line:match("^%s*$") then
      blank_lines = blank_lines + 1
      if blank_lines >= config.options.line_spacing then
        break
      end
    elseif blank_lines == 0 then
      break
    end

    row = row - 1
  end

  return first
end

local function last_bullet_line(lnum, min_indent)
  min_indent = min_indent or 0
  if min_indent < 0 then
    return -1
  end

  local last = -1
  local blank_lines = 0
  local row = lnum
  local line_count = vim.api.nvim_buf_line_count(0)

  while row <= line_count and line_indent(row) >= min_indent do
    local bullet, line = boundary_bullet_at(row)
    if bullet then
      last = row
      blank_lines = 0
    elseif line:match("^%s*$") then
      blank_lines = blank_lines + 1
      if blank_lines >= config.options.line_spacing then
        break
      end
    end

    row = row + 1
  end

  return last
end

local function ordered_state(bullet)
  local value = marker_number(bullet)
  if not value then
    return nil
  end

  return {
    index = 1,
    type = bullet.type,
    lower = bullet.marker == bullet.marker:lower(),
    closure = bullet.closure,
    spacing = bullet.spacing,
  }
end

local function reset_child_states(states, indent)
  for key, _ in pairs(states) do
    if key > indent then
      states[key] = nil
    end
  end
end

local function renumber_lines(first, last)
  local previous_indent = -1
  local states = {}

  for lnum = first, last do
    local bullet = bullet_at(lnum)
    if bullet then
      local indent = #bullet.indent
      if indent < previous_indent then
        reset_child_states(states, indent)
      end

      if is_ordered(bullet) then
        local state = states[indent]
        if not state or indent > previous_indent then
          state = ordered_state(bullet)
          states[indent] = state
        else
          state.index = state.index + 1
        end

        if state then
          local marker = number_marker(state.type, state.index, state.lower)
          if marker then
            local marker_prefix = marker .. state.closure .. state.spacing
            if state.pad_width and #marker_prefix < state.pad_width then
              marker_prefix = pad_right(marker_prefix, state.pad_width)
            elseif state.pad_width and #marker_prefix > state.pad_width then
              state.pad_width = #marker_prefix
            elseif not state.pad_width then
              state.pad_width = #marker_prefix
            end
            local prefix = bullet.indent .. marker_prefix
            vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { prefix .. bullet.text })
          end
        end
      end

      previous_indent = indent
    end
  end
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

  if is_empty_bullet_text(bullet.text) and delete_empty_bullet(lnum, bullet, mode) then
    return ""
  end

  local prefix
  if config.options.auto_indent_after_colon and ends_with_colon(bullet.text) then
    local child = child_bullet(bullet)
    if child then
      prefix = current_prefix(child)
    end
  end

  prefix = prefix or next_prefix(bullet)
  if not prefix then
    if mode == "n" then
      open_line_below()
      return ""
    end

    feed_cr()
    return ""
  end

  prefix = checkbox_continuation_prefix(bullet, prefix)

  local lines, cursor_index = spaced_lines(prefix)
  insert_lines(lnum, lines, cursor_index)
  vim.cmd.startinsert({ bang = true })

  return ""
end

function M.renumber_list()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local first = first_bullet_line(lnum)
  local last = last_bullet_line(lnum)
  if first > 0 and last > 0 then
    renumber_lines(first, last)
  end
end

function M.renumber_selection(first, last)
  first, last = visual_range(first, last)
  if first and last then
    renumber_lines(first, last)
  end
end

local function checkbox_item(lnum)
  local bullet, line = bullet_at(lnum)
  if not bullet then
    return nil, line
  end

  local checkbox = parse_checkbox_text(bullet.text)
  if not checkbox then
    return { lnum = lnum, bullet = bullet, checkbox = nil }, line
  end

  return { lnum = lnum, bullet = bullet, checkbox = checkbox, children = {} }, line
end

local function checkbox_tree(first, last)
  local items = {}
  local stack = {}

  for lnum = first, last do
    local item = checkbox_item(lnum)
    if item and item.checkbox then
      local indent = #item.bullet.indent
      while #stack > 0 and #stack[#stack].bullet.indent >= indent do
        table.remove(stack)
      end
      if #stack > 0 then
        table.insert(stack[#stack].children, item)
      end
      table.insert(stack, item)
      table.insert(items, item)
    end
  end

  return items
end

local function partial_marker(markers, checked, total)
  if checked == 0 then
    return markers[1]
  end
  if checked == total then
    return checkbox_checked_marker(markers)
  end

  local index = math.floor((checked / total) * (#markers - 2)) + 2
  index = math.max(2, math.min(#markers - 1, index))
  return markers[index]
end

local function recompute_items(items)
  for index = #items, 1, -1 do
    local item = items[index]
    if #item.children > 0 then
      local checked = 0
      for _, child in ipairs(item.children) do
        if checkbox_state(child.checkbox) == "checked" then
          checked = checked + 1
        end
      end

      local marker = partial_marker(item.checkbox.markers, checked, #item.children)
      item.checkbox.marker = marker
      item.checkbox.index = checkbox_marker_index(marker, item.checkbox.markers)
      set_checkbox_marker(item.lnum, item.bullet, item.checkbox, marker)
    elseif checkbox_state(item.checkbox) == "partial" then
      local marker = item.checkbox.markers[1]
      item.checkbox.marker = marker
      item.checkbox.index = 1
      set_checkbox_marker(item.lnum, item.bullet, item.checkbox, marker)
    end
  end
end

local function checkbox_range(lnum)
  local first = first_bullet_line(lnum)
  local last = last_bullet_line(lnum)
  return first > 0 and first or lnum, last > 0 and last or lnum
end

local function set_descendant_checkboxes(lnum, bullet, marker)
  local line_count = vim.api.nvim_buf_line_count(0)
  for row = lnum + 1, line_count do
    local item = checkbox_item(row)
    if item and item.bullet then
      if #item.bullet.indent <= #bullet.indent then
        break
      end
      if item.checkbox then
        item.checkbox.marker = marker
        item.checkbox.index = checkbox_marker_index(marker, item.checkbox.markers)
        set_checkbox_marker(row, item.bullet, item.checkbox, marker)
      end
    end
  end
end

function M.toggle_checkbox()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local item = checkbox_item(lnum)
  if not item or not item.checkbox then
    return
  end

  local markers = item.checkbox.markers
  local marker = checkbox_state(item.checkbox) == "checked" and markers[1] or checkbox_checked_marker(markers)
  item.checkbox.marker = marker
  item.checkbox.index = checkbox_marker_index(marker, markers)
  set_checkbox_marker(lnum, item.bullet, item.checkbox, marker)

  if config.options.nested_checkboxes then
    set_descendant_checkboxes(lnum, item.bullet, marker)
    local first, last = checkbox_range(lnum)
    recompute_items(checkbox_tree(first, last))
  end
end

function M.recompute_checkboxes()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local first, last = checkbox_range(lnum)
  recompute_items(checkbox_tree(first, last))
end

function M.demote()
  return change_current_line_level("demote")
end

function M.promote()
  return change_current_line_level("promote")
end

function M.demote_visual(first, last)
  return change_visual_level("demote", first, last)
end

function M.promote_visual(first, last)
  return change_visual_level("promote", first, last)
end

function M.select_checkbox() end

function M.select_checkbox_inside() end

function M.select_bullet() end

function M.select_bullet_text() end

return M
