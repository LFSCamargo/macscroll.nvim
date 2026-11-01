local M = {}

local function truthy(value)
  if type(value) == 'number' then
    return value ~= 0
  end
  return value and true or false
end

--- Normalize RPC / keymap arguments into integer dirs.
--- Option or Ctrl plus a vertical-only step becomes a horizontal step.
function M.normalize(horiz, vert, alt, ctrl)
  horiz = tonumber(horiz) or 0
  vert = tonumber(vert) or 0
  if horiz ~= 0 then
    horiz = horiz > 0 and 1 or -1
  end
  if vert ~= 0 then
    vert = vert > 0 and 1 or -1
  end
  if (truthy(alt) or truthy(ctrl)) and horiz == 0 and vert ~= 0 then
    horiz = vert
    vert = 0
  end
  return horiz, vert
end

return M
