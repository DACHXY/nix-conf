local util = require("lspconfig.util")

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
      },
    },
    setup = {},
  },
}
