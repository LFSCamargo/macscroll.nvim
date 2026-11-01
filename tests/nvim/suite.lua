-- Install the plugin on packpath and start Neovim the way a user would:
-- no --clean, no manual runtimepath prepend, only an isolated XDG home.

local src = debug.getinfo(1, 'S').source:sub(2)
local root = vim.env.MACSCROLL_ROOT or vim.fn.fnamemodify(src, ':p:h:h:h')
local home = vim.fn.tempname()
local config = home .. '/config'
local data = home .. '/data'
local state = home .. '/state'
local cache = home .. '/cache'
local pack = data .. '/nvim/site/pack/testing/start/macscroll.nvim'

local function fail(msg)
  io.stderr:write('FAIL: ' .. msg .. '\n')
  os.exit(1)
end

local function pass(msg)
  io.stdout:write('PASS: ' .. msg .. '\n')
end

vim.fn.mkdir(config .. '/nvim', 'p', 448)
vim.fn.mkdir(data .. '/nvim/site/pack/testing/start', 'p', 448)
vim.fn.mkdir(state .. '/nvim', 'p', 448)
vim.fn.mkdir(cache .. '/nvim', 'p', 448)
vim.fn.mkdir(home .. '/e2e', 'p', 448)

local link_ok, link_err = vim.uv.fs_symlink(root, pack)
if not link_ok then
  fail('could not install plugin on packpath: ' .. tostring(link_err))
end

local init_src = vim.fn.readfile(root .. '/tests/nvim/init.lua')
vim.fn.writefile(init_src, config .. '/nvim/init.lua')

local env = {
  HOME = home,
  PATH = vim.env.PATH,
  LANG = vim.env.LANG or 'C',
  TMPDIR = vim.env.TMPDIR or '/tmp',
  XDG_CONFIG_HOME = config,
  XDG_DATA_HOME = data,
  XDG_STATE_HOME = state,
  XDG_CACHE_HOME = cache,
  E2E_DIR = home .. '/e2e',
  NVIM_WRAPPER = '0',
  NVIM_APPNAME = 'nvim',
}

local sock = home .. '/nvim.sock'
local job = vim.fn.jobstart({
  vim.v.progpath,
  '--headless',
  '--listen',
  sock,
}, { env = env })
if job <= 0 then
  fail('could not start user-style Neovim')
end

local chan
local function stop()
  if chan then
    pcall(vim.fn.chanclose, chan)
  end
  pcall(vim.fn.jobstop, job)
  pcall(vim.uv.fs_unlink, sock)
end

local ready_at = vim.uv.now() + 4000
while vim.uv.now() < ready_at and not vim.uv.fs_stat(sock) do
  vim.wait(20)
end
if not vim.uv.fs_stat(sock) then
  stop()
  fail('user-style Neovim did not publish a listen socket')
end

local conn_ok, conn = pcall(vim.fn.sockconnect, 'pipe', sock, { rpc = true })
if not conn_ok then
  stop()
  fail('could not attach to user-style Neovim: ' .. tostring(conn))
end
chan = conn

local function lua(code)
  local ok, result = pcall(vim.fn.rpcrequest, chan, 'nvim_exec_lua', code, {})
  if not ok then
    stop()
    fail('nvim_exec_lua failed: ' .. tostring(result) .. ' in ' .. code)
  end
  if result == vim.NIL then
    return nil
  end
  return result
end

local loaded
for _ = 1, 50 do
  local ok, value = pcall(lua, 'return vim.g.loaded_macscroll == true')
  if ok and value == true then
    loaded = true
    break
  end
  vim.wait(50)
end
if not loaded then
  stop()
  fail('plugin/macscroll.lua did not load from pack/*/start')
end
pass('plugin loads from packpath start')

local rtp = lua('return vim.api.nvim_list_runtime_paths()')
local has_plugin = false
if type(rtp) == 'table' then
  for _, path in ipairs(rtp) do
    if type(path) == 'string' and path:find('macscroll', 1, true) then
      has_plugin = true
    end
  end
end
if not has_plugin then
  stop()
  fail('runtimepath must include the packpath install: ' .. vim.inspect(rtp))
end
if lua('return vim.fn.exists(":MacscrollBuild") == 2') ~= true then
  stop()
  fail(':MacscrollBuild must exist after plugin load')
end
if lua('return vim.fn.exists(":MacscrollStart") == 2') ~= true then
  stop()
  fail(':MacscrollStart must exist after plugin load')
end
if lua('return vim.fn.exists(":MacscrollStop") == 2') ~= true then
  stop()
  fail(':MacscrollStop must exist after plugin load')
end
pass('user commands are registered')

if lua('return require("macscroll").interactive()') ~= false then
  stop()
  fail('isolated E2E_DIR must keep the Darwin handler off')
end
if lua('return require("macscroll").ensure_worker()') ~= false then
  stop()
  fail('ensure_worker() must stay off in the nvim suite')
end
pass('auto setup ran without starting the worker')

lua([[
  local lines = {}
  for i = 1, 80 do
    lines[i] = string.rep('abcdefghijklmnopqrstuvwxyz', 8) .. tostring(i)
  end
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(buf)
  vim.wo.wrap = false
  vim.fn.winrestview({ leftcol = 0, topline = 1, lnum = 1, col = 0 })
]])

if lua('return require("macscroll").scroll(1, 1)') ~= true then
  stop()
  fail('scroll() must work after a packpath install')
end
local api_view = lua('return { vim.fn.winsaveview().leftcol, vim.fn.winsaveview().topline }')
if type(api_view) ~= 'table' or api_view[1] < 6 or api_view[2] < 4 then
  stop()
  fail('packpath session must move leftcol and topline')
end
pass('API scroll works in a packpath session')

lua('vim.fn.winrestview({ leftcol = 0, topline = 1, lnum = 1, col = 0 })')
local pos = lua('return vim.api.nvim_win_get_position(0)')
if type(pos) ~= 'table' then
  stop()
  fail('could not read window position for mouse wheel')
end
local row = (pos[1] or 0) + 2
local col = (pos[2] or 0) + 2
local mouse_ok, mouse_err = pcall(
  vim.fn.rpcrequest,
  chan,
  'nvim_input_mouse',
  'wheel',
  'right',
  '',
  0,
  row,
  col
)
if not mouse_ok then
  stop()
  fail('nvim_input_mouse wheel right failed: ' .. tostring(mouse_err))
end
local leftcol
for _ = 1, 40 do
  leftcol = lua('return vim.fn.winsaveview().leftcol')
  if type(leftcol) == 'number' and leftcol > 0 then
    break
  end
  vim.wait(50)
end
if type(leftcol) ~= 'number' or leftcol == 0 then
  stop()
  fail('<ScrollWheelRight> from nvim_input_mouse must move leftcol')
end
pass('real wheel event moves leftcol')

lua('vim.fn.winrestview({ leftcol = 0, topline = 1, lnum = 1, col = 0 })')
mouse_ok, mouse_err = pcall(
  vim.fn.rpcrequest,
  chan,
  'nvim_input_mouse',
  'wheel',
  'down',
  '',
  0,
  row,
  col
)
if not mouse_ok then
  stop()
  fail('nvim_input_mouse wheel down failed: ' .. tostring(mouse_err))
end
local topline
for _ = 1, 40 do
  topline = lua('return vim.fn.winsaveview().topline')
  if type(topline) == 'number' and topline > 1 then
    break
  end
  vim.wait(50)
end
if type(topline) ~= 'number' or topline <= 1 then
  stop()
  fail('<ScrollWheelDown> from nvim_input_mouse must move topline')
end
pass('real wheel event moves topline')

lua('vim.fn.winrestview({ leftcol = 0, topline = 1, lnum = 1, col = 0 })')
local plugin_sock = lua('return require("macscroll").listen({ force = true })')
if type(plugin_sock) ~= 'string' or not plugin_sock:match('/%d+%.sock$') then
  stop()
  fail('forced listen must publish a pid socket')
end
local worker = vim
  .system({
    vim.v.progpath,
    '--headless',
    '--server',
    plugin_sock,
    '--remote-expr',
    [[luaeval("require('macscroll').scroll(1,1,0,0)")]],
  }, { text = true, timeout = 4000 })
  :wait()
if worker.code ~= 0 then
  stop()
  fail('worker-style --remote-expr must reach the packpath session')
end
local view
for _ = 1, 40 do
  view = lua('return { vim.fn.winsaveview().leftcol, vim.fn.winsaveview().topline }')
  if type(view) == 'table' and view[1] > 0 and view[2] > 1 then
    break
  end
  vim.wait(50)
end
if type(view) ~= 'table' or view[1] == 0 or view[2] <= 1 then
  stop()
  fail('handler RPC must scroll a packpath session')
end
pass('handler --remote-expr reaches a user-style session')

lua('require("macscroll.health").check()')
pass('checkhealth macscroll runs')

lua('require("macscroll").stop()')
stop()
io.stdout:write('nvim suite passed\n')
