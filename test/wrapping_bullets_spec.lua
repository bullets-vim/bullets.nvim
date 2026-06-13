local helpers = require 'test.helpers'

describe('wrapped bullets', function()
  before_each(function()
    helpers.reset_config()
  end)

  it('inserts a new bullet after a wrapped bullet #WL-001', function()
    helpers.test_bullet_inserted('do that', {
      '# Hello there',
      '- do this',
      '  this is the second line of the first bullet',
    }, {
      '# Hello there',
      '- do this',
      '  this is the second line of the first bullet',
      '- do that',
    })
  end)

  it('does not insert wrapped bullets when disabled #WL-002', function()
    require('bullets').setup { enable_wrapped_lines = false }
    helpers.new_buffer {
      '# Hello there',
      '- do this',
      '  this is the second line of the first bullet',
    }
    helpers.feedkeys 'A<CR>'
    helpers.feedkeys 'ido that<Esc>'
    assert.are.same({
      '# Hello there',
      '- do this',
      '  this is the second line of the first bullet',
      'do that',
    }, helpers.get_lines())
  end)

  it('does not insert wrapped bullets unnecessarily #WL-003', function()
    -- When <CR> is pressed on a non-bullet line the plugin defers the actual
    -- newline via feedkeys('n'). Using two separate feedkeys calls ensures the
    -- deferred CR fires (the 'x' flag drains it) before we type the next text.
    vim.cmd 'enew'
    vim.bo.filetype = 'text'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      '# Hello there',
      '- do this',
      '  this is the second line of the first bullet',
      '',
      'no bullets after this line',
    })
    vim.api.nvim_win_set_cursor(0, { 5, #'no bullets after this line' })
    -- feedkeys 'tx' exits insert mode after draining typeahead. After the first
    -- call the plugin's deferred '\<CR>' has fired (new empty line 6) and we are
    -- in normal mode. The second call uses 'i' to re-enter insert before typing.
    helpers.feedkeys 'A<CR>'
    helpers.feedkeys 'ido that<Esc>'
    assert.are.same({
      '# Hello there',
      '- do this',
      '  this is the second line of the first bullet',
      '',
      'no bullets after this line',
      'do that',
    }, helpers.get_lines())
  end)

  it('does not insert wrapped bullets after whitespace-only separators #WL-004', function()
    helpers.new_buffer {
      '# Hello there',
      '- do this',
      '  this is the second line of the first bullet',
      '  ',
      '  no bullets after this line',
    }
    helpers.feedkeys 'A<CR>'
    helpers.feedkeys 'ido that<Esc>'
    assert.are.same({
      '# Hello there',
      '- do this',
      '  this is the second line of the first bullet',
      '  ',
      '  no bullets after this line',
      'do that',
    }, helpers.get_lines())
  end)
end)
