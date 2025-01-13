local util = require("lspconfig.util")
local async = require("lspconfig.async")
local mod_cache = nil

require("lspconfig").lua_ls.setup({
  on_init = function(client)
    local path = client.workspace_folders[1].name
    if vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
      return
    end

    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          -- Depending on the usage, you might want to add additional paths here.
          "${3rd}/luv/library",
          -- "${3rd}/busted/library",
        },
      },
    })
  end,
  settings = {
    Lua = {},
  },
})

return {
  {
    "neovim/nvim-lspconfig",
    event = "LazyFile",
    opts = {
      servers = {
        -- biome = {
        --   root_dir = function(fname)
        --     return util.root_pattern("biome.json", "biome.jsonc")(fname)
        --       or util.find_package_json_ancestor(fname)
        --       or vim.fs.find("node_modules", { path = fname, upward = true })[1]
        --       or util.find_node_modules_ancestor(fname)
        --       or util.find_git_ancestor(fname)
        --   end,
        -- },
        nil_ls = false,
        nixd = {
          cmd = { "nixd" },
          filetypes = { "nix" },
          single_file_support = true,
          root_dir = function(fname)
            return util.root_pattern("flake.nix")(fname)
              or vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
          end,
          settings = {
            nixd = {
              nixpkgs = {
                expr = "import <nixpkgs> { }",
              },
              formatting = {
                command = { "nixfmt" },
              },
              options = {
                nixos = {
                  expr = '(builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations.k-on.options',
                },
                home_manager = {
                  expr = '(builtins.getFlake ("git+file://" + toString ./.)).homeConfigurations."ruixi@k-on".options',
                },
              },
            },
          },
        },
        nginx_language_server = {
          cmd = { "nginx-language-server" },
          filetypes = { "nginx" },
          rootPatterns = { "nginx.conf", ".git" },
        },
        jsonls = {
          cmd = { "vscode-json-languageserver", "--stdio" },
          filetypes = { "json" },
        },
        vuels = {
          cmd = { "vue-language-server", "--stdio" },
          filetypes = { "vue" },
        },
        ts_ls = {
          cmd = { "typescript-language-server", "--stdio" },
          filetypes = { "vue", "ts", "tsx" },
        },
        clangd = {
          cmd = { "clangd" },
          root_markers = { ".git", ".clangd", "compile_commands.json" },
          filetypes = { "cpp", "c" },
          capabilities = {
            textDocument = {
              semanticTokens = {
                multilineTokenSupport = true,
              },
            },
          },
        },
        gopls = {
          cmd = { "gopls" },
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
          root_dir = function(fname)
            -- see: https://github.com/neovim/nvim-lspconfig/issues/804
            if not mod_cache then
              local result = async.run_command({ "go", "env", "GOMODCACHE" })

              if result and result[1] then
                mod_cache = vim.trim(result[1])
              else
                mod_cache = vim.fn.system("go env GOMODCACHE")
              end
            end
            if mod_cache and fname:sub(1, #mod_cache) == mod_cache then
              local clients = util.get_lsp_clients({ name = "gopls" })
              if #clients > 0 then
                return clients[#clients].config.root_dir
              end
            end
            return util.root_pattern("go.work", "go.mod", ".git")(fname)
          end,
          single_file_support = true,
        },
      },
    },
    setup = {},
  },
}
