local M = {}

M.defaults = {
  enabled_file_types = { "markdown", "text", "gitcommit" },
  enable_in_empty_buffers = false,
  set_mappings = true,
  mapping_leader = "",
  custom_mappings = {},
  delete_last_bullet_if_empty = 1,
  line_spacing = 1,
  pad_right = true,
  max_alpha_characters = 2,
  enable_roman_list = true,
  list_item_styles = { "-", "*+", ".+", "#.", "+", "\\item" },
  outline_levels = { "ROM", "ABC", "num", "abc", "rom", "std-", "std*", "std+" },
  renumber_on_change = true,
  nested_checkboxes = true,
  enable_wrapped_lines = true,
  checkbox_markers = " .oOX",
  checkbox_partials_toggle = 1,
  auto_indent_after_colon = true,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), options or {})
  return M.options
end

return M
