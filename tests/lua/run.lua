local src = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(src, ':p:h:h:h')
vim.opt.runtimepath:prepend(root)
vim.opt.packpath = ''

local failures = 0
local passed = 0

local function fail(name, err)
  failures = failures + 1
  io.stderr:write(string.format('FAIL %s: %s\n', name, err))
end

local function ok(name)
  passed = passed + 1
  io.stdout:write(string.format('PASS %s\n', name))
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error((msg or 'values differ') .. string.format(' (got %s, want %s)', vim.inspect(actual), vim.inspect(expected)))
  end
end

local dirs = require('macscroll.dirs')
local view = require('macscroll.view')
local config = require('macscroll.config')
local paths = require('macscroll.paths')

local cases = {
  {
    name = 'dirs.normalize keeps independent axes',
    run = function()
      local h, v = dirs.normalize(2, -3)
      assert_eq(h, 1)
      assert_eq(v, -1)
    end,
  },
  {
    name = 'dirs.normalize turns Option+vertical into horizontal',
    run = function()
      local h, v = dirs.normalize(0, 1, true, false)
      assert_eq(h, 1)
      assert_eq(v, 0)
    end,
  },
  {
    name = 'dirs.normalize turns Ctrl+vertical into horizontal',
    run = function()
      local h, v = dirs.normalize(0, -1, 0, 1)
      assert_eq(h, -1)
      assert_eq(v, 0)
    end,
  },
  {
    name = 'view.horiz moves leftcol and keeps the cursor in view',
    run = function()
      local next = view.horiz({ leftcol = 0, col = 0, curswant = 0 }, 10, 6, 1)
      assert_eq(next.leftcol, 6)
      assert_eq(next.col, 6)
    end,
  },
  {
    name = 'view.horiz never goes negative',
    run = function()
      local next = view.horiz({ leftcol = 2, col = 2 }, 10, 6, -1)
      assert_eq(next.leftcol, 0)
    end,
  },
  {
    name = 'view.vert moves topline and clamps to buffer end',
    run = function()
      local next = view.vert({ topline = 1, lnum = 1 }, 5, 8, 3, 1)
      assert_eq(next.topline, 4)
      next = view.vert({ topline = 4, lnum = 4 }, 5, 8, 3, 1)
      assert_eq(next.topline, 4)
    end,
  },
  {
    name = 'config.merge accepts a skip_buftypes list',
    run = function()
      local cfg = config.merge({ skip_buftypes = { 'prompt', 'terminal' } })
      assert_eq(cfg.skip_buftypes.prompt, true)
      assert_eq(cfg.skip_buftypes.terminal, true)
    end,
  },
  {
    name = 'paths resolve the handler package, not scripts/',
    run = function()
      assert_eq(paths.plugin_root(), root)
      assert_eq(paths.handler_package(), root .. '/handler/darwin')
      assert_eq(vim.fn.isdirectory(paths.handler_package()), 1)
      assert_eq(vim.fn.filereadable(root .. '/handler/darwin/Package.swift'), 1)
    end,
  },
  {
    name = 'socket_dir is under stdpath state',
    run = function()
      local dir = paths.socket_dir()
      assert_eq(dir:find('macscroll', 1, true) ~= nil, true)
      assert_eq(dir:find(vim.fn.stdpath('state'), 1, true) ~= nil, true)
    end,
  },
}

for _, case in ipairs(cases) do
  local ok_run, err = pcall(case.run)
  if ok_run then
    ok(case.name)
  else
    fail(case.name, err)
  end
end

io.stdout:write(string.format('lua unit tests: %d passed, %d failed\n', passed, failures))
if failures > 0 then
  os.exit(1)
end
