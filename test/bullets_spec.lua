local helpers = require("test.helpers")
local active_it = it
local it = pending

describe("Bullets.vim", function()
  describe("inserting new bullets", function()
    before_each(function()
      helpers.reset_config()
      vim.o.ignorecase = false
    end)

    describe("on return key when cursor is not at EOL", function()
      active_it("splits the line and does not add a bullet", function()
        -- G$i places cursor on last char 't' in "- this is the first bullet"
        -- i inserts before 't', CR is deferred (not at EOL), splits the line
        -- then "second bullet" is typed before 't': "second bullett"
        -- Temporarily disable formatoptions 'r' to avoid comment-leader insertion
        local saved_fo = vim.o.formatoptions
        vim.cmd("set formatoptions-=r")
        helpers.new_buffer({
          "# Hello there",
          "- this is the first bullet",
        })
        -- Position cursor on 't' (last char, 0-indexed col 25), enter insert before it
        -- CR is deferred by plugin (not at EOL); 'x' flag drains the deferred CR → split
        -- We end up in normal mode on new line with 't'
        helpers.feedkeys("G$i<CR>")
        -- Now in normal mode at col 0 of "t"; insert before 't' and type
        helpers.feedkeys("isecond bullet<Esc>")
        vim.o.formatoptions = saved_fo
        assert.are.same({
          "# Hello there",
          "- this is the first bulle",
          "second bullett",
        }, helpers.get_lines())
      end)
    end)

    describe("on return key when cursor is at EOL", function()
      active_it("adds a new bullet if the previous line had a known bullet type", function()
        helpers.test_bullet_inserted(
          "do that",
          { "# Hello there", "- do this" },
          { "# Hello there", "- do this", "- do that" }
        )
      end)

      active_it("adds a new latex bullet", function()
        helpers.test_bullet_inserted("Second item", {
          "\\documentclass{article}",
          "  \\begin{document}",
          "",
          "  \\begin{itemize}",
          "    \\item First item",
        }, {
          "\\documentclass{article}",
          "  \\begin{document}",
          "",
          "  \\begin{itemize}",
          "    \\item First item",
          "    \\item Second item",
        })
      end)

      active_it("adds a pandoc bullet if the prev line had one", function()
        helpers.test_bullet_inserted(
          "second bullet",
          { "Hello there", "#. this is the first bullet" },
          { "Hello there", "#. this is the first bullet", "#. second bullet" }
        )
      end)

      active_it("adds an Org mode bullet if the prev line had one", function()
        helpers.test_bullet_inserted(
          "second bullet",
          { "Hello there", "**** this is the first bullet" },
          { "Hello there", "**** this is the first bullet", "**** second bullet" }
        )
      end)

      active_it("adds a new numeric bullet if the previous line had numeric bullet", function()
        helpers.test_bullet_inserted(
          "second bullet",
          { "# Hello there", "1) this is the first bullet" },
          { "# Hello there", "1) this is the first bullet", "2) second bullet" }
        )
      end)

      active_it("adds a new numeric bullet with right padding", function()
        helpers.test_bullet_inserted(
          "second bullet",
          { "# Hello there", "1.  this is the first bullet" },
          { "# Hello there", "1.  this is the first bullet", "2.  second bullet" }
        )
      end)

      active_it("maintains total bullet width from 9. to 10. with reduced padding", function()
        require("bullets").setup({ renumber_on_change = false })
        helpers.test_bullet_inserted(
          "second bullet",
          { "# Hello there", "9.  this is the first bullet" },
          { "# Hello there", "9.  this is the first bullet", "10. second bullet" }
        )
      end)

      active_it("adds a new - bullet with right padding", function()
        helpers.test_bullet_inserted(
          "second bullet",
          { "# Hello there", "-   this is the first bullet" },
          { "# Hello there", "-   this is the first bullet", "-   second bullet" }
        )
      end)

      active_it("does not insert a new numeric bullet for decimal numbers", function()
        -- "3.14159 is an approximation of pi." is not a bullet line
        -- CR on non-bullet line is deferred, use two-call pattern
        helpers.new_buffer({
          "# Hello there",
          "3.14159 is an approximation of pi.",
        })
        helpers.feedkeys("A<CR>")
        helpers.feedkeys("isecond line<Esc>")
        assert.are.same({
          "# Hello there",
          "3.14159 is an approximation of pi.",
          "second line",
        }, helpers.get_lines())
      end)

      active_it("adds a new roman numeral bullet", function()
        require("bullets").setup({ pad_right = false })
        helpers.new_buffer({
          "# Hello there",
          "I. this is the first bullet",
        })
        helpers.feedkeys("A<CR>second bullet<CR>third bullet<CR>fourth bullet<CR>fifth bullet<Esc>")
        assert.are.same({
          "# Hello there",
          "I. this is the first bullet",
          "II. second bullet",
          "III. third bullet",
          "IV. fourth bullet",
          "V. fifth bullet",
        }, helpers.get_lines())
      end)

      active_it("adds a new lowercase roman numeral bullet", function()
        require("bullets").setup({ pad_right = false })
        helpers.new_buffer({
          "# Hello there",
          "i. this is the first bullet",
        })
        helpers.feedkeys("A<CR>second bullet<CR>third bullet<CR>fourth bullet<CR>fifth bullet<Esc>")
        assert.are.same({
          "# Hello there",
          "i. this is the first bullet",
          "ii. second bullet",
          "iii. third bullet",
          "iv. fourth bullet",
          "v. fifth bullet",
        }, helpers.get_lines())
      end)

      active_it("does not confuse with the 'ignorecase' option", function()
        vim.cmd("set ignorecase")
        -- "Vi." is mixed case / not a valid roman numeral bullet → non-bullet CR
        helpers.new_buffer({
          "# Hello there",
          "Vi. this is the first line",
        })
        helpers.feedkeys("A<CR>")
        helpers.feedkeys("isecond line<Esc>")
        assert.are.same({
          "# Hello there",
          "Vi. this is the first line",
          "second line",
        }, helpers.get_lines())
      end)

      active_it("does not insert a new roman bullets without following spaces", function()
        -- "m.example.com is a site." has no space after the dot → not a bullet
        helpers.new_buffer({
          "# Hello there",
          "m.example.com is a site.",
        })
        helpers.feedkeys("A<CR>")
        helpers.feedkeys("isecond line<Esc>")
        assert.are.same({
          "# Hello there",
          "m.example.com is a site.",
          "second line",
        }, helpers.get_lines())
      end)

      active_it("does not insert a new roman bullets for invalid roman numbers", function()
        -- "LID." is not a valid roman numeral, so no bullet continuation
        -- However lines typed after non-bullet lines also get no bullet
        helpers.new_buffer({
          "# Hello there",
          "LID. the first line",
        })
        -- First CR after "LID. the first line" (non-bullet) → deferred
        helpers.feedkeys("A<CR>")
        helpers.feedkeys("isecond line<Esc>")
        -- Now on "second line" (non-bullet) → deferred CR
        helpers.feedkeys("A<CR>")
        helpers.feedkeys("ivim. third line<Esc>")
        -- Now on "vim. third line" (non-bullet) → deferred CR
        helpers.feedkeys("A<CR>")
        helpers.feedkeys("ifourth line<Esc>")
        assert.are.same({
          "# Hello there",
          "LID. the first line",
          "second line",
          "vim. third line",
          "fourth line",
        }, helpers.get_lines())
      end)

      active_it("deletes the last bullet if it is empty", function()
        require("bullets").setup({ delete_last_bullet_if_empty = 1 })
        helpers.new_buffer({
          "# Hello there",
          "- this is the first bullet",
        })
        -- First CR creates "- " empty bullet, second CR on empty bullet deletes it
        helpers.feedkeys("A<CR><CR>")
        local lines = helpers.get_lines()
        -- Strip trailing empty lines before comparison.
        while #lines > 0 and lines[#lines] == "" do
          table.remove(lines)
        end
        assert.are.same({
          "# Hello there",
          "- this is the first bullet",
        }, lines)
      end)

      active_it("promotes the last bullet when configured to", function()
        require("bullets").setup({ delete_last_bullet_if_empty = 2 })
        helpers.new_buffer({
          "# Hello there",
          "- this is the first bullet",
          "  - this is the second bullet",
        })
        -- First CR creates new child bullet "  - ", second CR promotes (dedents)
        helpers.feedkeys("A<CR><CR>")
        local lines = helpers.get_lines()
        -- strip trailing empty lines
        while #lines > 0 and lines[#lines] == "" do
          table.remove(lines)
        end
        -- The promoted bullet has a trailing space ("- ") matching plugin output
        assert.are.same({
          "# Hello there",
          "- this is the first bullet",
          "  - this is the second bullet",
          "- ",
        }, lines)
      end)

      active_it("does not delete the last bullet when configured not to", function()
        require("bullets").setup({ delete_last_bullet_if_empty = 0 })
        helpers.new_buffer({
          "# Hello there",
          "- this is the first bullet",
        })
        -- First CR creates "- " empty bullet, second CR on empty bullet
        -- with config=0 does NOT delete it; a plain CR fires leaving "- " intact
        helpers.feedkeys("A<CR><CR>")
        local lines = helpers.get_lines()
        -- strip trailing empty lines
        while #lines > 0 and lines[#lines] == "" do
          table.remove(lines)
        end
        -- The non-deleted bullet retains trailing space ("- ") matching plugin output
        assert.are.same({
          "# Hello there",
          "- this is the first bullet",
          "- ",
        }, lines)
      end)

      active_it("adds configured blank spacing before the next bullet", function()
        require("bullets").setup({ line_spacing = 2 })
        helpers.test_bullet_inserted("second bullet", {
          "# Hello there",
          "1. first bullet",
        }, {
          "# Hello there",
          "1. first bullet",
          "",
          "2. second bullet",
        })
      end)

      active_it("can disable right padding for ordered bullets", function()
        require("bullets").setup({ pad_right = false })
        helpers.test_bullet_inserted("second bullet", {
          "# Hello there",
          "9.  first bullet",
        }, {
          "# Hello there",
          "9.  first bullet",
          "10. second bullet",
        })
      end)

      active_it("indents after a line ending in a colon", function()
        require("bullets").setup({ auto_indent_after_colon = true })
        helpers.new_buffer({
          "# Hello there",
          "a. first bullet",
        })
        helpers.feedkeys("A<CR>second bullet:<CR>third bullet<CR>fourth bullet<Esc>")
        assert.are.same({
          "# Hello there",
          "a. first bullet",
          "b. second bullet:",
          "  i. third bullet",
          "  ii. fourth bullet",
        }, helpers.get_lines())
      end)

      active_it("indents after a line ending in a fullwidth colon", function()
        require("bullets").setup({ auto_indent_after_colon = true })
        helpers.new_buffer({
          "# Hello there",
          "a. first bullet",
        })
        helpers.feedkeys("A<CR>second bullet：<CR>third bullet<Esc>")
        assert.are.same({
          "# Hello there",
          "a. first bullet",
          "b. second bullet：",
          "  i. third bullet",
        }, helpers.get_lines())
      end)

      active_it("can disable colon auto indentation", function()
        require("bullets").setup({ auto_indent_after_colon = false })
        helpers.test_bullet_inserted("second bullet:", {
          "# Hello there",
          "a. first bullet",
        }, {
          "# Hello there",
          "a. first bullet",
          "b. second bullet:",
        })
        helpers.feedkeys("A<CR>third bullet<Esc>")
        assert.are.same({
          "# Hello there",
          "a. first bullet",
          "b. second bullet:",
          "c. third bullet",
        }, helpers.get_lines())
      end)

      active_it("toggles roman numeral bullets with enable_roman_list", function()
        -- Disable alpha lists to isolate test to roman numerals
        require("bullets").setup({ max_alpha_characters = 0, enable_roman_list = true })
        helpers.new_buffer({
          "# Hello there",
          "i. this is the first bullet",
        })
        -- Type second and third bullets (roman numeral bullets)
        helpers.feedkeys("A<CR>second bullet<CR>third bullet<Esc>")
        -- Disable roman list mid-test
        require("bullets").setup({ max_alpha_characters = 0, enable_roman_list = false })
        -- Type fourth and fifth (no roman numeral prefix now)
        -- We're in normal mode, need to append and continue
        helpers.feedkeys("A<CR>")
        helpers.feedkeys("ifourth bullet<Esc>")
        helpers.feedkeys("A<CR>")
        helpers.feedkeys("ififth bullet<Esc>")
        assert.are.same({
          "# Hello there",
          "i. this is the first bullet",
          "ii. second bullet",
          "iii. third bullet",
          "fourth bullet",
          "fifth bullet",
        }, helpers.get_lines())
      end)
    end)
  end)
end)
