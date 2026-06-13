if vim.g.loaded_bullets_nvim then
  return
end

vim.g.loaded_bullets_nvim = true

local bullets = require 'bullets'
if not bullets.did_setup then
  bullets.setup()
end
