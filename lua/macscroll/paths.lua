local M = {}

function M.plugin_root()
  local src = debug.getinfo(1, 'S').source
  if type(src) ~= 'string' or src:sub(1, 1) ~= '@' then
    return nil
  end
  return vim.fn.fnamemodify(src:sub(2), ':p:h:h:h')
end

function M.handler_package()
  local root = M.plugin_root()
  if not root then
    return nil
  end
  return root .. '/handler/darwin'
end

function M.socket_dir()
  return vim.fn.stdpath('state') .. '/macscroll'
end

function M.worker_bin()
  return vim.fn.stdpath('data') .. '/macscroll/macscroll-worker'
end

return M
