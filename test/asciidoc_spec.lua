local helpers = require("test.helpers")
local active_it = it
local it = pending

describe("AsciiDoc", function()
  before_each(function()
    helpers.reset_config()
  end)

  active_it("maintains indentation in ascii doc bullets", function()
    helpers.test_bullet_inserted(
      "rats",
      { "= Pets!", "* dogs", "** cats" },
      { "= Pets!", "* dogs", "** cats", "** rats" }
    )
  end)

  active_it("supports dot bullets", function()
    helpers.test_bullet_inserted("cats", { "= Pets!", ". dogs" }, { "= Pets!", ". dogs", ". cats" })
  end)

  active_it("supports nested dot bullets", function()
    helpers.test_bullet_inserted(
      "rats",
      { "= Pets!", ". dogs", ".. cats" },
      { "= Pets!", ". dogs", ".. cats", ".. rats" }
    )
  end)
end)
