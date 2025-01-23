local util = require("lspconfig.util")

return {
  {
    "neovim/nvim-lspconfig",
    event = "LazyFile",
    opts = {
      on_init = function(client)
        local path = client.workspace_folders[1].name
        if vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc") then
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
        nginx_language_server = {
          cmd = { "nginx-language-server" },
          filetypes = { "nginx" },
          rootPatterns = { "biome.json", "biome.jsonc" },
        },
        volar = {
          init_options = {
            vue = {
              hybridMode = true,
            },
          },
          settings = {
            typescript = {
              inlayHints = {
                enumMemberValues = {
                  enabled = true,
                },
                functionLikeReturnTypes = {
                  enabled = true,
                },
                propertyDeclarationTypes = {
                  enabled = true,
                },
                parameterTypes = {
                  enabled = true,
                  suppressWhenArgumentMatchesName = true,
                },
                variableTypes = {
                  enabled = true,
                },
              },
            },
          },
        },
        vtsls = {},
        stylelint_lsp = {
          filetypes = { "css", "scss", "vue" },
          root_dir = util.root_pattern("packages.json", ".git"),
          debounce = 100,
          settings = {
            stylelintplus = {
              autoFixOnFormat = true,
              autoFixOnSave = true,
            },
          },
          on_attach = function(client)
            client.server_capabilities.document_formatting = false
          end,
        },
      },
      setup = {},
    },
  },
}
