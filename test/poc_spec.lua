local function feedkeys(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "tx", false)
end

describe("Bullets.vim", function()
  before_each(function()
    require("bullets").setup({
      enabled_file_types = { "text" },
      enable_in_empty_buffers = false,
      set_mappings = true,
      mapping_leader = "",
      custom_mappings = {},
    })
  end)

  it("loads the plugin", function()
    assert.equals(2, vim.fn.exists(":InsertNewBullet"))
  end)

  it("preserves native normal-mode o behavior", function()
    vim.cmd("enew")
    vim.bo.filetype = "text"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "plain" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    feedkeys("ohello<Esc>")

    assert.are.same({ "plain", "hello" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it("preserves native insert-mode return fallback", function()
    vim.cmd("enew")
    vim.bo.filetype = "text"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "plain" })
    vim.api.nvim_win_set_cursor(0, { 1, #"plain" })

    feedkeys("A<CR>next<Esc>")

    assert.are.same({ "plain", "next" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it("does not install default mappings when disabled", function()
    require("bullets").setup({
      enabled_file_types = { "text" },
      set_mappings = false,
    })
    vim.cmd("enew")
    vim.bo.filetype = "text"

    assert.equals("", vim.fn.maparg("o", "n"))
    assert.equals("", vim.fn.maparg(">>", "n"))
  end)

  it("inserts a new bullet on <CR>", function()
    vim.cmd("enew")
    vim.bo.filetype = "text"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- first item" })
    vim.api.nvim_win_set_cursor(0, { 1, #"- first item" })

    feedkeys("A<CR>")

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.equals("- ", lines[2])
  end)
end)
