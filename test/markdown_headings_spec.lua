local helpers = require 'test.helpers'

describe('markdown headings', function()
  local function markdown_buffer(lines)
    helpers.new_buffer(lines)
    vim.bo.filetype = 'markdown'
  end

  before_each(function()
    helpers.reset_config()
    require('bullets').setup { markdown_headings = true }
  end)

  it('demotes a heading #ON-019', function()
    markdown_buffer { '# Title', '## Section' }

    helpers.feedkeys 'G>>'

    assert.are.same({ '# Title', '### Section' }, helpers.get_lines())
  end)

  it('demotes a heading with the insert mapping #ON-019', function()
    markdown_buffer { '## Section' }

    helpers.feedkeys 'A<C-t>'

    assert.are.same({ '### Section' }, helpers.get_lines())
  end)

  it('promotes a heading #ON-020', function()
    markdown_buffer { '# Title', '### Section' }

    helpers.feedkeys 'G<<'

    assert.are.same({ '# Title', '## Section' }, helpers.get_lines())
  end)

  it('promotes an empty heading #ON-020', function()
    markdown_buffer { '##' }

    vim.cmd 'BulletPromote'

    assert.are.same({ '#' }, helpers.get_lines())
  end)

  it('does not promote past level 1 or demote past level 6 #ON-021', function()
    markdown_buffer { '# Title', '###### Deepest' }

    helpers.feedkeys 'gg<<'
    helpers.feedkeys 'G>>'

    assert.are.same({ '# Title', '###### Deepest' }, helpers.get_lines())
  end)

  it('ignores heading-like lines in fenced code blocks #ON-022', function()
    markdown_buffer { '```sh', '# comment', '```' }

    helpers.feedkeys 'ggj'
    vim.cmd 'BulletDemote'

    assert.are.same({ '```sh', '# comment', '```' }, helpers.get_lines())
  end)

  it('ignores heading-like lines in front matter #ON-022', function()
    markdown_buffer { '---', '# comment', '---', '# Title' }

    helpers.feedkeys 'ggj'
    vim.cmd 'BulletDemote'
    helpers.feedkeys 'G'
    vim.cmd 'BulletDemote'

    assert.are.same({ '---', '# comment', '---', '## Title' }, helpers.get_lines())
  end)

  it('does not treat hashtags as headings #ON-022', function()
    markdown_buffer { '#tag' }

    vim.cmd 'BulletDemote'

    assert.are.same({ '#tag' }, helpers.get_lines())
  end)

  it('leaves headings unchanged when disabled #ON-023', function()
    helpers.reset_config()
    markdown_buffer { '## Section' }

    vim.cmd 'BulletDemote'

    assert.are.same({ '## Section' }, helpers.get_lines())
  end)

  it('changes headings and list items in visual ranges #ON-024', function()
    require('bullets').setup { markdown_headings = true, outline_levels = { 'std-', 'std*' } }
    markdown_buffer { '## Section', '- item' }
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 2

    vim.cmd '1,2BulletDemoteVisual'
    assert.are.same({ '### Section', '  * item' }, helpers.get_lines())

    vim.cmd '1,2BulletPromoteVisual'
    assert.are.same({ '## Section', '- item' }, helpers.get_lines())
  end)
end)
