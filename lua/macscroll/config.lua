local M = {}

M.defaults = {
  horiz_step = 6,
  vert_step = 3,
  mouse = true,
  keymaps = true,
  auto_worker = true,
  skip_buftypes = { prompt = true },
}

local function as_set(value)
  if type(value) ~= 'table' then
    return { prompt = true }
  end
  if value[1] then
    local set = {}
    for _, name in ipairs(value) do
      set[name] = true
    end
    return set
  end
  return value
end

function M.merge(opts)
  local cfg = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), type(opts) == 'table' and opts or {})
  cfg.skip_buftypes = as_set(cfg.skip_buftypes)
  return cfg
end

return M
