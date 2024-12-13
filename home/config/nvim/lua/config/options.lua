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
