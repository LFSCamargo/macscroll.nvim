local src = debug.getinfo(1, 'S').source:sub(2)
local root = vim.env.MACSCROLL_ROOT or vim.fn.fnamemodify(src, ':p:h:h:h')
local init = root .. '/tests/e2e/init.lua'

local function fail(msg)
  io.stderr:write('FAIL: ' .. msg .. '\n')
  os.exit(1)
end

local function pass(msg)
  io.stdout:write('PASS: ' .. msg .. '\n')
end

local job = vim.fn.jobstart({
  vim.v.progpath,
  '--clean',
  '--headless',
  '--embed',
  '-u',
  init,
}, { rpc = true })
if job <= 0 then
  fail('could not start child Neovim')
end

local function stop()
  pcall(vim.fn.jobstop, job)
end

local function lua(code)
  local ok, result = pcall(vim.fn.rpcrequest, job, 'nvim_exec_lua', code, {})
  if not ok then
    stop()
    fail('nvim_exec_lua failed: ' .. tostring(result) .. ' in ' .. code)
  end
  if result == vim.NIL then
    return nil
  end
  return result
end

if lua('return require("macscroll").interactive()') ~= false then
  stop()
  fail('e2e must set E2E_DIR so the Darwin handler stays off')
end
if lua('return require("macscroll").listen()') ~= nil then
  stop()
  fail('listen() must stay off without force during e2e')
end
if lua('return require("macscroll").ensure_worker()') ~= false then
  stop()
  fail('ensure_worker() must stay off during e2e')
end
pass('handler stays off in e2e')

if lua("return type(vim.fn.maparg('<ScrollWheelRight>', 'n', false, true).callback)") ~= 'function' then
  stop()
  fail('ScrollWheelRight must call macscroll, not zh/zl')
end
if lua("return type(vim.fn.maparg('<A-ScrollWheelDown>', 'n', false, true).callback)") ~= 'function' then
  stop()
  fail('Option+vertical wheel must call macscroll')
end
pass('wheel maps are bound')

if lua("return vim.o.mouse:find('a', 1, true) ~= nil") ~= true then
  stop()
  fail('mouse must accept wheel events')
end
if lua('return vim.o.sidescroll == 1 and vim.o.sidescrolloff == 0') ~= true then
  stop()
  fail('sidescroll options must let leftcol move from column 0')
end
pass('mouse and sidescroll options')

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

if lua('return require("macscroll").scroll(1, 0)') ~= true then
  stop()
  fail('horizontal scroll() must succeed')
end
if lua('return vim.fn.winsaveview().leftcol') < 6 then
  stop()
  fail('scroll(1, 0) must move leftcol by horiz_step')
end
pass('scroll() moves leftcol')

lua('vim.fn.winrestview({ leftcol = 0, topline = 1, lnum = 1, col = 0 })')
if lua('return require("macscroll").scroll(0, 1)') ~= true then
  stop()
  fail('vertical scroll() must succeed')
end
if lua('return vim.fn.winsaveview().topline') < 4 then
  stop()
  fail('scroll(0, 1) must move topline by vert_step')
end
pass('scroll() moves topline')

lua('vim.fn.winrestview({ leftcol = 0, topline = 1, lnum = 1, col = 0 })')
lua('return require("macscroll").scroll(0, 1, true, false)')
local after_alt = lua('return { vim.fn.winsaveview().leftcol, vim.fn.winsaveview().topline }')
if type(after_alt) ~= 'table' or after_alt[1] < 6 or after_alt[2] ~= 1 then
  stop()
  fail('Option+vertical must sidescroll and leave topline')
end
pass('Option+vertical becomes horizontal')

lua('vim.fn.winrestview({ leftcol = 0, topline = 1, lnum = 1, col = 0 })')
local plugin_sock = lua('return require("macscroll").listen({ force = true })')
if type(plugin_sock) ~= 'string' or not plugin_sock:match('/%d+%.sock$') then
  stop()
  fail('forced listen must publish a pid socket under macscroll/')
end
if plugin_sock:find('%.%.', 1, true) then
  stop()
  fail('socket path must reject parent segments')
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
  fail('worker-style --remote-expr must reach Neovim: ' .. (worker.stderr or worker.stdout or ''))
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
  fail('--remote-expr must move both leftcol and topline')
end
pass('forced listen accepts --remote-expr for both axes')

lua('require("macscroll").stop()')
if lua(('return vim.uv.fs_stat(%q) ~= nil'):format(plugin_sock)) == true then
  stop()
  fail('stop() must remove the listen socket')
end
pass('stop() closes the socket')

stop()
io.stdout:write('e2e tests passed\n')
