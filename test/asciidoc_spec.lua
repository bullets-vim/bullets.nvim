local helpers = require 'test.helpers'

describe('AsciiDoc', function()
  before_each(function()
    helpers.reset_config()
  end)

  it('maintains indentation in ascii doc bullets #MR-004', function()
    helpers.test_bullet_inserted(
      'rats',
      { '= Pets!', '* dogs', '** cats' },
      { '= Pets!', '* dogs', '** cats', '** rats' }
    )
  end)

  it('supports dot bullets #MR-005', function()
    helpers.test_bullet_inserted('cats', { '= Pets!', '. dogs' }, { '= Pets!', '. dogs', '. cats' })
  end)

  it('supports nested dot bullets #MR-005', function()
    helpers.test_bullet_inserted(
      'rats',
      { '= Pets!', '. dogs', '.. cats' },
      { '= Pets!', '. dogs', '.. cats', '.. rats' }
    )
  end)
end)
