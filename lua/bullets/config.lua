local M = {}

---@alias bullets.MappingMode string|string[]
---@alias bullets.MappingRhs string|function

---@class bullets.CustomMapping
---@field [1] bullets.MappingMode
---@field [2] string
---@field [3] bullets.MappingRhs

---@class bullets.Config
---@field enabled_file_types? string[] Filetypes where bullets.nvim attaches.
---@field enable_in_empty_buffers? boolean Attach to buffers with an empty filetype.
---@field set_mappings? boolean Install default buffer-local mappings.
---@field mapping_leader? string Prefix added before default mappings.
---@field custom_mappings? bullets.CustomMapping[] Extra buffer-local mappings passed to `vim.keymap.set` as `{ mode, lhs, rhs }`.
---@field delete_last_bullet_if_empty? 0|1|2 Behavior when continuing an empty bullet.
---@field line_spacing? integer Blank lines inserted between continued bullets.
---@field pad_right? boolean Pad ordered-list prefixes to keep text aligned.
---@field max_alpha_characters? integer Maximum length for alphabetic list markers.
---@field enable_roman_list? boolean Enable roman numeral list markers.
---@field list_item_styles? string[] List marker styles recognized by the parser.
---@field outline_levels? string[] Marker styles used when promoting or demoting bullets.
---@field renumber_on_change? boolean Renumber affected lists after structural changes.
---@field nested_checkboxes? boolean Recompute parent checkbox states from children.
---@field enable_wrapped_lines? boolean Keep wrapped list text aligned.
---@field checkbox_markers? string Characters used as checkbox states.
---@field checkbox_partials_toggle? 0|1 How partial checkbox states toggle.
---@field auto_indent_after_colon? boolean Indent a new child item after a bullet ending in `:`.

---@type bullets.Config
M.defaults = {
  enabled_file_types = { 'markdown', 'text', 'gitcommit' },
  enable_in_empty_buffers = false,
  set_mappings = true,
  mapping_leader = '',
  custom_mappings = {},
  delete_last_bullet_if_empty = 1,
  line_spacing = 1,
  pad_right = true,
  max_alpha_characters = 2,
  enable_roman_list = true,
  list_item_styles = { '-', '*+', '.+', '#.', '+', '\\item' },
  outline_levels = { 'ROM', 'ABC', 'num', 'abc', 'rom', 'std-', 'std*', 'std+' },
  renumber_on_change = true,
  nested_checkboxes = true,
  enable_wrapped_lines = true,
  checkbox_markers = ' .oOX',
  checkbox_partials_toggle = 1,
  auto_indent_after_colon = true,
}

---@type bullets.Config
M.options = vim.deepcopy(M.defaults)

---@param options? bullets.Config
---@return bullets.Config
function M.setup(options)
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), options or {})
  return M.options
end

return M
