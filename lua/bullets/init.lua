local config = require("bullets.config")

local M = {}

local augroup = vim.api.nvim_create_augroup("bullets.nvim", { clear = true })

local function actions()
  return require("bullets.actions")
end

local function command(name, fn, opts)
  vim.api.nvim_create_user_command(name, fn, vim.tbl_extend("force", { force = true }, opts or {}))
end

local function map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { silent = true }, opts or {}))
end

local function map_buffer(buf, mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { buffer = buf, silent = true }, opts or {}))
end

local function add_commands()
  command("InsertNewBullet", function()
    actions().insert_new_bullet()
  end)
  command("RenumberList", function()
    actions().renumber_list()
  end)
  command("RenumberSelection", function()
    actions().renumber_selection()
  end, { range = true })
  command("ToggleCheckbox", function()
    actions().toggle_checkbox()
  end)
  command("RecomputeCheckboxes", function()
    actions().recompute_checkboxes()
  end)
  command("BulletDemote", function()
    actions().demote()
  end)
  command("BulletPromote", function()
    actions().promote()
  end)
  command("BulletDemoteVisual", function()
    actions().demote_visual()
  end, { range = true })
  command("BulletPromoteVisual", function()
    actions().promote_visual()
  end, { range = true })
  command("SelectCheckbox", function()
    actions().select_checkbox()
  end)
  command("SelectCheckboxInside", function()
    actions().select_checkbox_inside()
  end)
  command("SelectBullet", function()
    actions().select_bullet()
  end)
  command("SelectBulletText", function()
    actions().select_bullet_text()
  end)
end

local function add_plug_mappings()
  map("i", "<Plug>(bullets-newline)", function()
    return actions().insert_new_bullet()
  end, { expr = true })
  map("n", "<Plug>(bullets-newline)", function()
    actions().insert_new_bullet()
  end)
  map("n", "<Plug>(bullets-renumber)", function()
    actions().renumber_list()
  end)
  map("x", "<Plug>(bullets-renumber)", function()
    actions().renumber_selection()
  end)
  map("n", "<Plug>(bullets-toggle-checkbox)", function()
    actions().toggle_checkbox()
  end)
  map("n", "<Plug>(bullets-recompute-checkboxes)", function()
    actions().recompute_checkboxes()
  end)
  map({ "i", "n" }, "<Plug>(bullets-demote)", function()
    actions().demote()
  end)
  map("x", "<Plug>(bullets-demote)", function()
    actions().demote_visual()
  end)
  map({ "i", "n" }, "<Plug>(bullets-promote)", function()
    actions().promote()
  end)
  map("x", "<Plug>(bullets-promote)", function()
    actions().promote_visual()
  end)
end

local function add_default_mappings(buf)
  local opts = config.options
  local leader = opts.mapping_leader

  map_buffer(buf, "i", leader .. "<CR>", "<Plug>(bullets-newline)", { remap = true })
  map_buffer(buf, "i", leader .. "<C-CR>", "<CR>")
  map_buffer(buf, "n", leader .. "o", "<Plug>(bullets-newline)", { remap = true })
  map_buffer(buf, "n", leader .. "gN", "<Plug>(bullets-renumber)", { remap = true })
  map_buffer(buf, "x", leader .. "gN", "<Plug>(bullets-renumber)", { remap = true })
  map_buffer(buf, "n", leader .. "<leader>x", "<Plug>(bullets-toggle-checkbox)", { remap = true })
  map_buffer(buf, "i", leader .. "<C-t>", "<Plug>(bullets-demote)", { remap = true })
  map_buffer(buf, "n", leader .. ">>", "<Plug>(bullets-demote)", { remap = true })
  map_buffer(buf, "x", leader .. ">", "<Plug>(bullets-demote)", { remap = true })
  map_buffer(buf, "i", leader .. "<C-d>", "<Plug>(bullets-promote)", { remap = true })
  map_buffer(buf, "n", leader .. "<<", "<Plug>(bullets-promote)", { remap = true })
  map_buffer(buf, "x", leader .. "<", "<Plug>(bullets-promote)", { remap = true })
end

local function add_custom_mappings(buf)
  for _, item in ipairs(config.options.custom_mappings) do
    map_buffer(buf, item[1], item[2], item[3], { remap = true })
  end
end

local function configure_buffer(buf)
  if config.options.set_mappings then
    add_default_mappings(buf)
  end
  add_custom_mappings(buf)
end

local function add_autocmds()
  vim.api.nvim_clear_autocmds({ group = augroup })

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = config.options.enabled_file_types,
    callback = function(event)
      configure_buffer(event.buf)
    end,
  })

  if config.options.enable_in_empty_buffers then
    vim.api.nvim_create_autocmd({ "BufNew", "BufRead" }, {
      group = augroup,
      pattern = "*",
      callback = function(event)
        if vim.bo[event.buf].filetype == "" then
          configure_buffer(event.buf)
        end
      end,
    })
  end
end

function M.setup(options)
  config.setup(options)
  add_commands()
  add_plug_mappings()
  add_autocmds()
end

return M
