local M = {}

-- Replaces termcodes and feeds keys synchronously (including mapped keys)
function M.feedkeys(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "tx", false)
end

-- Opens a fresh buffer with the given lines and the 'text' filetype,
-- positions the cursor at the end of the last line, and returns the bufnr.
function M.new_buffer(lines)
  vim.cmd("enew")
  vim.bo.filetype = "text"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  local last = #lines
  vim.api.nvim_win_set_cursor(0, { last, #lines[last] })
  return vim.api.nvim_get_current_buf()
end

-- Returns all lines of the current buffer.
function M.get_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

-- Sets up a buffer with initial_lines, appends second_bullet via <CR>,
-- then asserts the buffer matches expected_lines.
function M.test_bullet_inserted(second_bullet, initial_lines, expected_lines)
  M.new_buffer(initial_lines)
  M.feedkeys("A<CR>" .. second_bullet)
  assert.are.same(expected_lines, M.get_lines())
end

-- Resets bullets.nvim to the plugin defaults used by the specs.
-- Call in before_each for any describe block that mutates config.
function M.reset_config()
  vim.g.bullets_line_spacing = nil
  require("bullets").setup({
    enabled_file_types = { "markdown", "text", "gitcommit", "scratch" },
    enable_in_empty_buffers = true,
    set_mappings = true,
    mapping_leader = "",
    custom_mappings = {},
    max_alpha_characters = 2,
    auto_indent_after_colon = true,
    line_spacing = 1,
    renumber_on_change = true,
    nested_checkboxes = true,
    checkbox_markers = " .oOX",
    checkbox_partials_toggle = 1,
    outline_levels = { "ROM", "ABC", "num", "abc", "rom", "std-", "std*", "std+" },
    enable_roman_list = true,
    enable_wrapped_lines = true,
    pad_right = true,
    delete_last_bullet_if_empty = 1,
  })
end

return M
