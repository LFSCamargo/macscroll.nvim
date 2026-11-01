if vim.g.loaded_macscroll or vim.g.macscroll_disable then
  return
end
vim.g.loaded_macscroll = true

vim.api.nvim_create_user_command('MacscrollBuild', function()
  local ok, msg = require('macscroll').build()
  if ok then
    vim.notify('macscroll: built ' .. msg, vim.log.levels.INFO)
  else
    vim.notify('macscroll: ' .. msg, vim.log.levels.ERROR)
  end
end, { desc = 'Compile the macscroll Swift worker' })

vim.api.nvim_create_user_command('MacscrollStart', function()
  require('macscroll').listen({ force = true })
  require('macscroll').ensure_worker()
end, { desc = 'Listen and start the macscroll worker' })

vim.api.nvim_create_user_command('MacscrollStop', function()
  require('macscroll').stop()
end, { desc = 'Stop the macscroll RPC socket' })

if vim.g.macscroll_auto ~= false then
  require('macscroll').setup(vim.g.macscroll_opts)
end
