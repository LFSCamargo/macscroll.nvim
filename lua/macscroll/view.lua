local M = {}

function M.horiz(view, text_width, step, dir)
  if dir == 0 then
    return view
  end
  text_width = math.max(1, tonumber(text_width) or 1)
  step = math.max(1, tonumber(step) or 1)
  local left = math.max(0, (view.leftcol or 0) + (step * dir))
  view.leftcol = left
  local col = view.col or 0
  if col < left then
    view.col = left
    view.curswant = left
  elseif col > left + text_width - 1 then
    view.col = left + text_width - 1
    view.curswant = view.col
  end
  return view
end

function M.vert(view, height, last, step, dir)
  if dir == 0 then
    return view
  end
  height = math.max(1, tonumber(height) or 1)
  last = math.max(1, tonumber(last) or 1)
  step = math.max(1, tonumber(step) or 1)
  local max_top = math.max(1, last - height + 1)
  local top = math.max(1, math.min(max_top, (view.topline or 1) + (step * dir)))
  view.topline = top
  local lnum = view.lnum or 1
  if lnum < top then
    view.lnum = top
  elseif lnum > top + height - 1 then
    view.lnum = top + height - 1
  end
  return view
end

return M
