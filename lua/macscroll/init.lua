-- macOS trackpad / mouse-wheel scrolling for Neovim.
-- The Darwin handler swallows CGEvent scrollWheel events and RPCs here
-- so terminals cannot drop axis-2 or rewrite axis-1 before Neovim sees them.

local config = require('macscroll.config')
local dirs = require('macscroll.dirs')
local paths = require('macscroll.paths')
local view = require('macscroll.view')

local M = {}

local sock
local started = false
local maps_set = false
local cfg = config.merge()

local WHEEL = {
  { '<ScrollWheelLeft>', -1, 0 },
  { '<ScrollWheelRight>', 1, 0 },
  { '<ScrollWheelUp>', 0, -1 },
  { '<ScrollWheelDown>', 0, 1 },
  { '<A-ScrollWheelUp>', 0, -1, true, false },
  { '<A-ScrollWheelDown>', 0, 1, true, false },
  { '<C-ScrollWheelUp>', 0, -1, false, true },
  { '<C-ScrollWheelDown>', 0, 1, false, true },
  { '<A-ScrollWheelLeft>', -1, 0, true, false },
  { '<A-ScrollWheelRight>', 1, 0, true, false },
  { '<C-ScrollWheelLeft>', -1, 0, false, true },
  { '<C-ScrollWheelRight>', 1, 0, false, true },
}

M.socket_dir = paths.socket_dir
M.worker_bin = paths.worker_bin
M.handler_package = paths.handler_package

function M.interactive()
  return vim.env.E2E_DIR == nil and #vim.api.nvim_list_uis() > 0
end

local function skip_win(win)
  if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
    return true
  end
  local buf = vim.api.nvim_win_get_buf(win)
  return cfg.skip_buftypes[vim.bo[buf].buftype] == true
end

local function target_win()
  local pos = vim.fn.getmousepos()
  if not skip_win(pos.winid) then
    return pos.winid
  end
  local cur = vim.api.nvim_get_current_win()
  if not skip_win(cur) then
    return cur
  end
  return nil
end

local function apply_horiz(win, dir)
  if dir == 0 then
    return
  end
  vim.wo[win].wrap = false
  vim.wo[win].sidescrolloff = 0
  local saved = vim.fn.winsaveview()
  local info = vim.fn.getwininfo(win)[1]
  local text_width = 1
  if info then
    text_width = math.max(1, info.width - info.textoff)
  end
  vim.fn.winrestview(view.horiz(saved, text_width, cfg.horiz_step, dir))
end

local function apply_vert(win, dir)
  if dir == 0 then
    return
  end
  vim.wo[win].scrolloff = 0
  local saved = vim.fn.winsaveview()
  local info = vim.fn.getwininfo(win)[1]
  local height = 1
  if info then
    height = math.max(1, info.height)
  end
  local last = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win))
  vim.fn.winrestview(view.vert(saved, height, last, cfg.vert_step, dir))
end

--- Apply a scroll step. Called from the Darwin handler over --remote-expr
--- and from <ScrollWheel*> maps if a TTY event still arrives.
function M.scroll(horiz, vert, alt, ctrl)
  horiz, vert = dirs.normalize(horiz, vert, alt, ctrl)
  if horiz == 0 and vert == 0 then
    return false
  end
  local win = target_win()
  if not win then
    return false
  end
  vim.api.nvim_win_call(win, function()
    apply_horiz(win, horiz)
    apply_vert(win, vert)
  end)
  return true
end

function M.listen(opts)
  opts = type(opts) == 'table' and opts or {}
  if not opts.force and not M.interactive() then
    return nil
  end
  if type(sock) == 'string' then
    return sock
  end
  vim.fn.mkdir(M.socket_dir(), 'p', 448)
  local path = M.socket_dir() .. '/' .. tostring(vim.fn.getpid()) .. '.sock'
  if type(path) ~= 'string' or path:find('%.%.', 1, true) then
    return nil
  end
  local ok = pcall(vim.fn.serverstart, path)
  if ok then
    sock = path
  end
  return sock
end

local function copy_worker(built, dest)
  vim.fn.mkdir(vim.fn.fnamemodify(dest, ':h'), 'p', 448)
  local ok, err = vim.uv.fs_copyfile(built, dest)
  if not ok then
    return false, err or 'could not copy worker'
  end
  vim.fn.setfperm(dest, 'rwxr-xr-x')
  return true, dest
end

function M.build()
  if vim.fn.has('mac') == 0 then
    return false, 'macscroll is macOS-only'
  end
  if vim.fn.executable('swift') == 0 then
    return false, 'swift not found; install Xcode Command Line Tools'
  end
  local pkg = paths.handler_package()
  if not pkg or vim.fn.isdirectory(pkg) == 0 then
    return false, 'missing handler package at handler/darwin'
  end
  local build = vim.system({
    'swift',
    'build',
    '-c',
    'release',
    '--package-path',
    pkg,
    '--product',
    'macscroll-worker',
  }, { text = true }):wait()
  if build.code ~= 0 then
    return false, build.stderr or 'swift build failed'
  end
  local shown = vim.system({
    'swift',
    'build',
    '-c',
    'release',
    '--package-path',
    pkg,
    '--show-bin-path',
  }, { text = true }):wait()
  if shown.code ~= 0 then
    return false, shown.stderr or 'could not locate built worker'
  end
  local built = vim.trim(shown.stdout or '') .. '/macscroll-worker'
  if vim.fn.executable(built) == 0 then
    return false, 'built worker missing at ' .. built
  end
  return copy_worker(built, M.worker_bin())
end

function M.ensure_worker()
  if not M.interactive() or vim.fn.has('mac') == 0 then
    return false
  end
  local bin = M.worker_bin()
  if vim.fn.executable(bin) == 0 then
    local ok = M.build()
    if not ok then
      return false
    end
  end
  if vim.fn.system({ 'pgrep', '-x', 'macscroll-worker' }):find('%d') then
    return true
  end
  vim.fn.jobstart({ bin }, { detach = true })
  return true
end

function M.stop()
  if type(sock) == 'string' then
    pcall(vim.fn.serverstop, sock)
    pcall(vim.uv.fs_unlink, sock)
    sock = nil
  end
end

local function bind_keymaps()
  if maps_set or not cfg.keymaps then
    return
  end
  maps_set = true
  local prefixes = { '', '2-', '3-', '4-' }
  local modes = { 'n', 'v', 'x', 's', 'i', 't' }
  for _, prefix in ipairs(prefixes) do
    for _, spec in ipairs(WHEEL) do
      local key, h, v, alt, ctrl = spec[1], spec[2], spec[3], spec[4], spec[5]
      local lhs = '<' .. prefix .. key:sub(2)
      vim.keymap.set(modes, lhs, function()
        M.scroll(h, v, alt, ctrl)
      end, { silent = true, desc = 'macscroll' })
    end
  end
end

local function apply_options()
  if cfg.mouse then
    vim.opt.mouse = 'a'
    vim.opt.mousemoveevent = true
  end
  vim.opt.sidescroll = 1
  vim.opt.sidescrolloff = 0
end

function M.setup(opts)
  cfg = config.merge(opts)
  apply_options()
  bind_keymaps()
  if started then
    return M
  end
  started = true
  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('macscroll', { clear = true }),
    callback = function()
      M.listen()
      if cfg.auto_worker then
        M.ensure_worker()
      end
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('macscroll_leave', { clear = true }),
    callback = M.stop,
  })
  if vim.v.vim_did_enter == 1 then
    M.listen()
    if cfg.auto_worker then
      M.ensure_worker()
    end
  end
  return M
end

return M
