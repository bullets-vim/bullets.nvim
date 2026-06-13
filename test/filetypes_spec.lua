local helpers = require 'test.helpers'

describe('filetypes', function()
  it('does not create mapping for bullets on empty buffer by default #ACT-006', function()
    require('bullets').setup { enable_in_empty_buffers = false }
    vim.cmd 'enew'
    vim.cmd 'setlocal formatoptions= comments=' -- prevent '#' comment-continuation
    helpers.feedkeys 'i# Hello there<CR>- this is the first bullet<CR>this is the second bullet<Esc>'
    assert.are.same({ '# Hello there', '- this is the first bullet', 'this is the second bullet' }, helpers.get_lines())
  end)

  it('should have a text-compatible filetype for .txt #ACT-007', function()
    local tmpfile = vim.fn.tempname() .. '.txt'
    vim.cmd('edit ' .. tmpfile)
    local ft = vim.bo.filetype
    assert.is_true(ft == 'text' or ft == 'markdown', "Expected 'text' or 'markdown' filetype, got: " .. tostring(ft))
    vim.cmd 'bdelete!'
  end)
end)
