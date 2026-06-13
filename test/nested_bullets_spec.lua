local helpers = require 'test.helpers'

describe('Bullets.vim', function()
  describe('nested bullets', function()
    local function repeat_command(command, count)
      for _ = 1, count do
        vim.cmd(command)
      end
    end

    before_each(function()
      helpers.reset_config()
      -- Plugin uses `normal! >>` / `normal! <<` internally which respect shiftwidth/expandtab.
      -- Set noexpandtab + shiftwidth=tabstop=4 so one indent level = one tab character.
      vim.opt.expandtab = false
      vim.opt.shiftwidth = 4
      vim.opt.tabstop = 4
    end)

    it('demotes a bullet one outline level #ON-001', function()
      helpers.new_buffer {
        '# Hello there',
        'I. this is the first bullet',
        'II. second bullet',
      }

      helpers.feedkeys 'gg2j>>'

      assert.are.same({
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
      }, helpers.get_lines())
    end)

    it('promotes a bullet one outline level #ON-002', function()
      helpers.new_buffer {
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
        '\tB. third bullet',
      }

      helpers.feedkeys 'gg3j<<'

      assert.are.same({
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
        'II. third bullet',
      }, helpers.get_lines())
    end)

    it('demotes an empty bullet #ON-011', function()
      helpers.new_buffer {
        '# Hello there',
        'I. this is the first bullet',
      }

      helpers.feedkeys 'GA<CR><C-t>second bullet<Esc>'

      assert.are.same({
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
      }, helpers.get_lines())
    end)

    it('promotes an empty bullet #ON-012', function()
      helpers.new_buffer {
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
      }

      helpers.feedkeys 'GA<CR><C-d>third bullet<Esc>'

      assert.are.same({
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
        'II. third bullet',
      }, helpers.get_lines())
    end)

    it('uses configured outline levels #ON-004', function()
      require('bullets').setup { outline_levels = { 'num', 'ABC', 'std*' } }
      helpers.new_buffer {
        '# Hello there',
        '1. first bullet',
        '\tA. second bullet',
        '\t\t* third bullet',
        '2. fourth bullet',
      }

      vim.api.nvim_win_set_cursor(0, { 5, 0 })
      vim.cmd 'BulletDemote'
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      vim.cmd 'BulletPromote'
      vim.api.nvim_win_set_cursor(0, { 4, 0 })
      vim.cmd 'BulletDemote'

      assert.are.same({
        '# Hello there',
        '1. first bullet',
        '2. second bullet',
        '\t\t\t* third bullet',
        '\tA. fourth bullet',
      }, helpers.get_lines())
    end)

    it('preserves the last standard outline level when demoting beyond configured levels #ON-005', function()
      helpers.new_buffer {
        '# Hello there',
        '\t\t\t\t\t\t\t+ ninth bullet',
      }

      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      vim.cmd 'BulletDemote'

      assert.are.same({
        '# Hello there',
        '\t\t\t\t\t\t\t\t+ ninth bullet',
      }, helpers.get_lines())
    end)

    it('removes a bullet when promoting at the top outline level #ON-003', function()
      helpers.new_buffer {
        '# Hello there',
        'I. first bullet',
      }

      helpers.feedkeys 'ggj<<'

      assert.are.same({
        '# Hello there',
        'first bullet',
      }, helpers.get_lines())
    end)

    it('promotes bullets in a visual range #ON-006', function()
      require('bullets').setup { outline_levels = { 'num', 'abc', 'std*' } }
      helpers.new_buffer {
        '# Hello there',
        '1. first bullet',
        '\ta. second bullet',
        '\tb. third bullet',
      }

      vim.cmd '3,4BulletPromoteVisual'

      assert.are.same({
        '# Hello there',
        '1. first bullet',
        '2. second bullet',
        '3. third bullet',
      }, helpers.get_lines())
    end)

    it('demotes bullets in a visual range #ON-007', function()
      require('bullets').setup { outline_levels = { 'num', 'abc', 'std*' } }
      helpers.new_buffer {
        '# Hello there',
        '1. first bullet',
        '2. second bullet',
        '3. third bullet',
      }

      vim.cmd '3,4BulletDemoteVisual'

      assert.are.same({
        '# Hello there',
        '1. first bullet',
        '\ta. second bullet',
        '\tb. third bullet',
      }, helpers.get_lines())
    end)

    it('demotes an existing bullet #ON-001', function()
      helpers.new_buffer {
        '# Hello there',
        'I. this is the first bullet',
        'II. second bullet',
        'III. third bullet',
        'IV. fourth bullet',
        'V. fifth bullet',
        'VI. sixth bullet',
        'VII. seventh bullet',
        'VIII. eighth bullet',
        'IX. ninth bullet',
      }
      for lnum = 3, 10 do
        vim.api.nvim_win_set_cursor(0, { lnum, 0 })
        repeat_command('BulletDemote', lnum - 2)
      end

      assert.are.same({
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
        '\t\t1. third bullet',
        '\t\t\ta. fourth bullet',
        '\t\t\t\ti. fifth bullet',
        '\t\t\t\t\t- sixth bullet',
        '\t\t\t\t\t\t* seventh bullet',
        '\t\t\t\t\t\t\t+ eighth bullet',
        '\t\t\t\t\t\t\t\t+ ninth bullet',
      }, helpers.get_lines())
    end)

    it('promotes an existing bullet #ON-002', function()
      helpers.new_buffer {
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
        '\t\t1. third bullet',
        '\t\t\ta. fourth bullet',
        '\t\t\t\ti. fifth bullet',
        '\t\t\t\t\t- sixth bullet',
        '\t\t\t\t\t\t* seventh bullet',
        '\t\t\t\t\t\t\t+ eighth bullet',
      }
      local promotions = {
        { lnum = 3, count = 1 },
        { lnum = 4, count = 1 },
        { lnum = 5, count = 2 },
        { lnum = 6, count = 4 },
        { lnum = 7, count = 5 },
        { lnum = 8, count = 6 },
        { lnum = 9, count = 7 },
      }
      for _, promotion in ipairs(promotions) do
        vim.api.nvim_win_set_cursor(0, { promotion.lnum, 0 })
        repeat_command('BulletPromote', promotion.count)
      end

      assert.are.same({
        '# Hello there',
        'I. this is the first bullet',
        'II. second bullet',
        '\tA. third bullet',
        '\tB. fourth bullet',
        'III. fifth bullet',
        'IV.  sixth bullet',
        'V.   seventh bullet',
        'VI.  eighth bullet',
      }, helpers.get_lines())
    end)

    it('restarts numbering with multiple outlines #ON-013', function()
      helpers.new_buffer {
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
        '',
        'A. first bullet',
      }
      helpers.feedkeys 'A<CR><C-t>second bullet<Esc>'
      assert.are.same({
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
        '',
        'A. first bullet',
        '\t1. second bullet',
      }, helpers.get_lines())
    end)

    it('works with custom outline level definitions #ON-004', function()
      require('bullets').setup { outline_levels = { 'num', 'ABC', 'std*' } }
      helpers.new_buffer {
        '# Hello there',
      }
      -- Enter insert at end, CR (non-bullet line header, deferred CR)
      helpers.feedkeys 'GA<CR>'
      -- Now in normal mode on new empty line - type the first bullet
      helpers.feedkeys 'i1. first bullet<Esc>'
      -- CR on bullet line - stays in insert after plugin fires
      helpers.feedkeys 'A<CR>second bullet<Esc>'
      -- CR on bullet line, then demote, then type
      helpers.feedkeys 'A<CR><C-t>third bullet<Esc>'
      helpers.feedkeys 'A<CR>fourth bullet<Esc>'
      helpers.feedkeys 'A<CR><C-t>fifth bullet<Esc>'
      helpers.feedkeys 'A<CR>sixth bullet<Esc>'
      helpers.feedkeys 'A<CR><C-t>seventh bullet<Esc>'
      helpers.feedkeys 'A<CR>eighth bullet<Esc>'
      -- promote twice, then type
      helpers.feedkeys 'A<CR><C-d><C-d>ninth bullet<Esc>'
      -- promote once, then type
      helpers.feedkeys 'A<CR><C-d>tenth bullet<Esc>'
      helpers.feedkeys 'A<CR>eleventh bullet<Esc>'
      assert.are.same({
        '# Hello there',
        '1. first bullet',
        '2. second bullet',
        '\tA. third bullet',
        '\tB. fourth bullet',
        '\t\t* fifth bullet',
        '\t\t* sixth bullet',
        '\t\t\t* seventh bullet',
        '\t\t\t* eighth bullet',
        '\tC. ninth bullet',
        '3. tenth bullet',
        '4. eleventh bullet',
      }, helpers.get_lines())
    end)

    it('promotes and demotes from different starting levels #ON-014', function()
      helpers.new_buffer {
        '# Hello there',
        '1. this is the first bullet',
        '\ta. second bullet',
        '+ fourth bullet',
        '* sixth bullet',
      }
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      vim.cmd 'BulletPromote'
      helpers.feedkeys 'A<CR><C-t>third bullet<Esc>'
      vim.api.nvim_win_set_cursor(0, { 5, #'+ fourth bullet' })
      helpers.feedkeys 'A<CR><C-t>fifth bullet<Esc>'
      vim.api.nvim_win_set_cursor(0, { 7, #'* sixth bullet' })
      helpers.feedkeys 'A<CR><C-t>seventh bullet<Esc>'
      assert.are.same({
        '# Hello there',
        '1. this is the first bullet',
        '2. second bullet',
        '\ta. third bullet',
        '+ fourth bullet',
        '\tA. fifth bullet',
        '* sixth bullet',
        '\t+ seventh bullet',
      }, helpers.get_lines())
    end)

    it('does not nest beyond defined levels #ON-005', function()
      helpers.new_buffer {
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
        '\t\t1. third bullet',
        '\t\t\ta. fourth bullet',
        '\t\t\t\ti. fifth bullet',
        '\t\t\t\tii. sixth bullet',
        '\t\t\t\t\t- seventh bullet',
        '\t\t\t\t\t\t* eighth bullet',
        '\t\t\t\t\t\t\t+ ninth bullet',
      }
      -- GA enters insert at end, CR on bullet line, demote with <C-t>, type
      helpers.feedkeys 'GA<CR><C-t>tenth bullet<Esc>'
      helpers.feedkeys 'A<CR>eleventh bullet<Esc>'
      assert.are.same({
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
        '\t\t1. third bullet',
        '\t\t\ta. fourth bullet',
        '\t\t\t\ti. fifth bullet',
        '\t\t\t\tii. sixth bullet',
        '\t\t\t\t\t- seventh bullet',
        '\t\t\t\t\t\t* eighth bullet',
        '\t\t\t\t\t\t\t+ ninth bullet',
        '\t\t\t\t\t\t\t\t+ tenth bullet',
        '\t\t\t\t\t\t\t\t+ eleventh bullet',
      }, helpers.get_lines())
    end)

    it('removes bullet when promoting top level bullet #ON-003', function()
      helpers.new_buffer {
        '# Hello there',
        'A. this is the first bullet',
        '',
        'I. second bullet',
        '\tA. third bullet',
      }
      -- Go to line 2 (gg + j), promote with <<
      helpers.feedkeys 'ggj<<'
      -- Go to line 5 (3j from line 2 = line 5), enter insert, promote twice
      helpers.feedkeys '3ji<C-d><C-d>'
      assert.are.same({
        '# Hello there',
        'this is the first bullet',
        '',
        'I. second bullet',
        'third bullet',
      }, helpers.get_lines())
    end)

    it('handle standard bullets when they are not in outline list #ON-015', function()
      require('bullets').setup { outline_levels = { 'num', 'ABC' } }
      helpers.new_buffer {
        '# Hello there',
        '1. this is the first bullet',
        '\t- standard bullet',
      }
      -- GA enters insert at end, CR on bullet line (standard bullet), type
      helpers.feedkeys 'GA<CR>second standard bullet<Esc>'
      -- CR on bullet line, promote with <C-d>, type
      helpers.feedkeys 'A<CR><C-d>second bullet<Esc>'
      -- CR on bullet line, type
      helpers.feedkeys 'A<CR>third bullet<Esc>'
      assert.are.same({
        '# Hello there',
        '1. this is the first bullet',
        '\t- standard bullet',
        '\t- second standard bullet',
        '2. second bullet',
        '3. third bullet',
      }, helpers.get_lines())
    end)

    it('adds new nested bullets with correct alpha/roman numerals #ON-016', function()
      helpers.new_buffer {
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
      }
      helpers.feedkeys 'GA<CR><C-t>third bullet<Esc>'
      helpers.feedkeys 'A<CR><C-t>fourth bullet<Esc>'
      helpers.feedkeys 'A<CR><C-t>fifth bullet<Esc>'
      helpers.feedkeys 'A<CR><C-t>sixth bullet<Esc>'
      helpers.feedkeys 'A<CR>seventh bullet<Esc>'
      helpers.feedkeys 'A<CR><C-d>eighth bullet<Esc>'
      helpers.feedkeys 'A<CR><C-d>ninth bullet<Esc>'
      helpers.feedkeys 'A<CR><C-d>tenth bullet<Esc>'
      helpers.feedkeys 'A<CR><C-d>eleventh bullet<Esc>'
      helpers.feedkeys 'A<CR><C-d>twelfth bullet<Esc>'
      assert.are.same({
        '# Hello there',
        'I. this is the first bullet',
        '\tA. second bullet',
        '\t\t1. third bullet',
        '\t\t\ta. fourth bullet',
        '\t\t\t\ti. fifth bullet',
        '\t\t\t\t\t- sixth bullet',
        '\t\t\t\t\t- seventh bullet',
        '\t\t\t\tii. eighth bullet',
        '\t\t\tb. ninth bullet',
        '\t\t2. tenth bullet',
        '\tB. eleventh bullet',
        'II. twelfth bullet',
      }, helpers.get_lines())
    end)

    it('changes levels in visual mode #ON-017', function()
      require('bullets').setup { outline_levels = { 'num', 'abc', 'std*' } }
      helpers.new_buffer {
        '# Hello there',
        '1. first bullet',
        '\ta. second bullet',
        '\tb. third bullet',
        '\t\t* fourth bullet',
        '\t\t* fifth bullet',
        '\t\t\tsixth bullet',
        '\t\t* seventh bullet',
        '2. eighth bullet',
        '\t\ta. ninth bullet',
        '\ta. tenth bullet',
        '\tb. eleventh bullet',
        '3. twelfth bullet',
        '\t thirteenth bullet',
        '\ta. fourteenth bullet',
        '\t\t* fifteenth bullet',
        '4. sixteenth bullet',
      }
      vim.cmd '4,4BulletPromoteVisual'
      vim.cmd '5,6BulletPromoteVisual'
      vim.cmd '8,8BulletDemoteVisual'
      vim.cmd '9,9BulletDemoteVisual'
      vim.cmd '10,10BulletPromoteVisual'
      vim.cmd '11,11BulletPromoteVisual'
      vim.cmd '12,12BulletDemoteVisual'
      vim.cmd '17,17BulletDemoteVisual'
      assert.are.same({
        '# Hello there',
        '1. first bullet',
        '\ta. second bullet',
        '2. third bullet',
        '\tb. fourth bullet',
        '\tc. fifth bullet',
        '\t\t\tsixth bullet',
        '\t\t\t* seventh bullet',
        '\td. eighth bullet',
        '\t1. ninth bullet',
        '3. tenth bullet',
        '\t\t* eleventh bullet',
        '3. twelfth bullet',
        '\t thirteenth bullet',
        '\ta. fourteenth bullet',
        '\t\t* fifteenth bullet',
        '\tb. sixteenth bullet',
      }, helpers.get_lines())
    end)

    it('add and change bullets with multiple line spacing and wrapped lines #ON-018', function()
      require('bullets').setup { line_spacing = 2 }
      helpers.new_buffer {
        '# Hello there',
        'I. this is the first bullet',
      }
      -- GA enters insert at end, CR on bullet line (with line_spacing=2, creates empty line too)
      -- Then type 'second bullet', then CR again, demote, type 'third bullet'
      helpers.feedkeys 'GA<CR>second bullet<Esc>'
      helpers.feedkeys 'A<CR><C-t>third bullet<Esc>'
      -- After CR on bullet line with line_spacing=2, cursor is on the new empty line after the bullet
      -- dd deletes that line, then inserts a wrapped line indented past the bullet prefix.
      helpers.feedkeys 'A<CR>'
      helpers.feedkeys 'dd'
      helpers.feedkeys 'i    wrapped bullet<Esc>'
      -- Then CR, type 'fourth bullet'
      helpers.feedkeys 'A<CR>fourth bullet<Esc>'
      assert.are.same({
        '# Hello there',
        'I. this is the first bullet',
        '',
        'II. second bullet',
        '',
        '\tA. third bullet',
        '    wrapped bullet',
        '',
        '\tB. fourth bullet',
      }, helpers.get_lines())
    end)

    it('indents after a line ending in a colon #ON-008 #ON-009', function()
      require('bullets').setup { auto_indent_after_colon = true }
      helpers.new_buffer {
        '# Hello there',
        'a. this is the first bullet',
      }
      -- GA enters insert at end, CR on bullet line, type second bullet ending with colon
      helpers.feedkeys 'GA<CR>this is the second bullet:<Esc>'
      -- CR after colon should auto-indent
      helpers.feedkeys 'A<CR>this bullet is indented<Esc>'
      helpers.feedkeys 'A<CR>this bullet is also indented<Esc>'
      -- Check first phase
      local lines1 = helpers.get_lines()
      -- Remove trailing empty lines before comparison.
      while #lines1 > 0 and lines1[#lines1] == '' do
        table.remove(lines1)
      end
      assert.are.same({
        '# Hello there',
        'a. this is the first bullet',
        'b. this is the second bullet:',
        '\ti. this bullet is indented',
        '\tii. this bullet is also indented',
      }, lines1)

      -- Phase 2: reset buffer with same content, test fullwidth colon
      helpers.new_buffer {
        '# Hello there',
        'a. this is the first bullet',
      }
      -- Use GA to enter insert at end of the last line.
      helpers.feedkeys 'GA<CR>this is the second bullet that ends with fullwidth colon：<Esc>'
      helpers.feedkeys 'A<CR>this bullet is indented<Esc>'
      helpers.feedkeys 'A<CR>this bullet is also indented<Esc>'
      local lines2 = helpers.get_lines()
      while #lines2 > 0 and lines2[#lines2] == '' do
        table.remove(lines2)
      end
      assert.are.same({
        '# Hello there',
        'a. this is the first bullet',
        'b. this is the second bullet that ends with fullwidth colon：',
        '\ti. this bullet is indented',
        '\tii. this bullet is also indented',
      }, lines2)
    end)
  end)
end)
