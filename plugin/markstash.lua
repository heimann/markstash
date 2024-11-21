-- Prevent loading this file multiple times
if vim.g.loaded_markstash == 1 then
  return
end
vim.g.loaded_markstash = 1

-- Create user commands that we'll use to control the plugin
vim.api.nvim_create_user_command("MarkStash", function()
  require("markstash").toggle()
end, {})
