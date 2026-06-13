---@meta

---@alias BustedCallback fun()

---@param name string
---@param callback BustedCallback
function describe(name, callback) end

---@param name string
---@param callback BustedCallback
function it(name, callback) end

---@param name string
---@param callback BustedCallback
function active_it(name, callback) end

---@param callback BustedCallback
function before_each(callback) end

---@param callback BustedCallback
function after_each(callback) end

---@param name string
---@param callback? BustedCallback
function pending(name, callback) end

---@class LuassertChain
---@field same fun(expected: any, actual: any, message?: string)
---@field equals fun(expected: any, actual: any, message?: string)
---@field is_true fun(value: any, message?: string)

---@class Luassert: LuassertChain
---@field are LuassertChain

---@type Luassert|function
assert = assert
