local busted = require 'plenary.busted'

local file = vim.env.SPEC_FILE
local tag = vim.env.SPEC_TAG

if not file or file == '' then
  error 'SPEC_FILE is required'
end

if not tag or tag == '' then
  error 'SPEC_TAG is required'
end

local original_it = it
local original_pending = pending

it = function(desc, fn)
  if desc:find('#' .. tag, 1, true) then
    return original_it(desc, fn)
  end
end

pending = function(desc, fn)
  if desc:find('#' .. tag, 1, true) then
    return original_pending(desc, fn)
  end
end

busted.run(file)
