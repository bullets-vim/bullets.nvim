if vim.g.loaded_bullets_nvim then
  return
end

vim.g.loaded_bullets_nvim = true

require("bullets").setup()
