local M = {}

function M.check()
  vim.health.start('macscroll')
  local scroll = require('macscroll')
  if vim.fn.has('mac') == 0 then
    vim.health.warn('Not macOS; the Swift worker will not start. Wheel maps still apply.')
    return
  end
  vim.health.ok('macOS detected')

  if vim.fn.executable('swift') == 1 then
    vim.health.ok('swift is available')
  else
    vim.health.warn('swift missing; the handler cannot be built')
  end

  local pkg = require('macscroll.paths').handler_package()
  if pkg and vim.fn.filereadable(pkg .. '/Package.swift') == 1 then
    vim.health.ok('handler package: ' .. pkg)
  else
    vim.health.error('handler/darwin/Package.swift is missing')
  end

  local bin = scroll.worker_bin()
  if vim.fn.executable(bin) == 1 then
    vim.health.ok('worker binary: ' .. bin)
  else
    vim.health.warn('worker binary missing at ' .. bin .. '; run :MacscrollBuild')
  end

  if vim.fn.system({ 'pgrep', '-x', 'macscroll-worker' }):find('%d') then
    vim.health.ok('macscroll-worker is running')
  else
    vim.health.warn('macscroll-worker is not running')
  end

  local dir = scroll.socket_dir()
  if vim.fn.isdirectory(dir) == 1 then
    vim.health.ok('socket dir: ' .. dir)
  else
    vim.health.info('socket dir not created yet: ' .. dir)
  end

  vim.health.info('Allow Accessibility for macscroll-worker in System Settings → Privacy & Security.')
end

return M
