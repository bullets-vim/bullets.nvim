local M = {}

local roman_values = {
  { 1000, 'm' },
  { 900, 'cm' },
  { 500, 'd' },
  { 400, 'cd' },
  { 100, 'c' },
  { 90, 'xc' },
  { 50, 'l' },
  { 40, 'xl' },
  { 10, 'x' },
  { 9, 'ix' },
  { 5, 'v' },
  { 4, 'iv' },
  { 1, 'i' },
}

function M.abc_to_number(value)
  local result = 0
  local lower = value:lower()

  for i = 1, #lower do
    result = result * 26 + lower:byte(i) - string.byte 'a' + 1
  end

  return result
end

function M.number_to_abc(value, lower)
  local base = lower and string.byte 'a' or string.byte 'A'
  local result = ''

  while value > 0 do
    value = value - 1
    result = string.char(base + value % 26) .. result
    value = math.floor(value / 26)
  end

  return result
end

function M.roman_to_number(value)
  local roman = value:lower()
  local result = 0
  local index = 1

  while index <= #roman do
    local matched = false
    for _, pair in ipairs(roman_values) do
      local number, letters = pair[1], pair[2]
      if roman:sub(index, index + #letters - 1) == letters then
        result = result + number
        index = index + #letters
        matched = true
        break
      end
    end

    if not matched then
      return nil
    end
  end

  return result
end

function M.number_to_roman(value, lower)
  local result = ''

  for _, pair in ipairs(roman_values) do
    local number, letters = pair[1], pair[2]
    while value >= number do
      result = result .. letters
      value = value - number
    end
  end

  if lower then
    return result
  end

  return result:upper()
end

function M.is_roman(value)
  local number = M.roman_to_number(value)
  if not number then
    return false
  end

  return M.number_to_roman(number, value == value:lower()) == value
end

return M
