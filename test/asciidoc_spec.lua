local helpers = require("test.helpers")
local it = pending

describe("AsciiDoc", function()
  it("maintains indentation in ascii doc bullets", function()
    helpers.test_bullet_inserted(
      "rats",
      { "= Pets!", "* dogs", "** cats" },
      { "= Pets!", "* dogs", "** cats", "** rats" }
    )
  end)

  it("supports dot bullets", function()
    helpers.test_bullet_inserted("cats", { "= Pets!", ". dogs" }, { "= Pets!", ". dogs", ". cats" })
  end)

  it("supports nested dot bullets", function()
    helpers.test_bullet_inserted(
      "rats",
      { "= Pets!", ". dogs", ".. cats" },
      { "= Pets!", ". dogs", ".. cats", ".. rats" }
    )
  end)
end)
