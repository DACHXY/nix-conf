-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

function GetAvailableWindowsShell()
  local shellList = { "nu", "pwsh-preview", "pwsh", "powershell", "cmd" }
  local length = #shellList
  for i = 1, length do
    local commandToCheck = "where " .. shellList[i]
    local exitCode = os.execute(commandToCheck)
    if exitCode == 0 then
      return shellList[i]
    end
  end

  return shellList[length - 1]
end

if package.config:sub(1, 1) == "\\" then
  vim.o.shell = GetAvailableWindowsShell()
end

vim.g.lazyvim_python_lsp = "pyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.lazyvim_eslint_auto_format = true
vim.o.background = "dark"

-- Markdown preview
vim.g.mkdp_auto_close = 0
vim.g.mkdp_combine_preview = 1
vim.g.mkdp_echo_preview_url = 1
vim.g.mkdp_open_to_the_world = 1
vim.g.mkdp_port = "20088"
