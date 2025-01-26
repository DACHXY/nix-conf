{
  lib,
  pkgs,
  device-name,
  username,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [
    gh
  ];

  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    withPython3 = true;
    extraPython3Packages = (
      plugins: with plugins; [
        debugpy
      ]
    );

    withNodeJs = true;

    extraPackages = with pkgs; [
      lua-language-server
      stylua
      ripgrep
      vue-language-server
      dockerfile-language-server-nodejs
      ruff
      ruff-lsp
      hadolint
      cmake-language-server
      cmake-lint
      cmake-format
      markdownlint-cli2
      marksman
      csharpier
      netcoredbg
      black
      prettierd
      biome
      eslint
      typescript-language-server
      typescript
      vtsls
      stylelint-lsp
      stylelint
      clang-tools
      taplo
      zls
    ];

    plugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];

    extraLuaConfig =
      let
        plugins = with pkgs.vimPlugins; [
          # LazyVim
          LazyVim
          bufferline-nvim
          cmp-buffer
          cmp-nvim-lsp
          cmp-path
          cmp-git
          blink-cmp
          crates-nvim
          conform-nvim
          dashboard-nvim
          dressing-nvim
          flash-nvim
          friendly-snippets
          gitsigns-nvim
          grug-far-nvim
          indent-blankline-nvim
          lazydev-nvim
          lualine-nvim
          luvit-meta
          neo-tree-nvim
          neotest
          noice-nvim
          nui-nvim
          nvim-cmp
          nvim-lint
          nvim-lspconfig
          nvim-snippets
          nvim-treesitter
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-ts-autotag
          nvim-ts-context-commentstring
          nvim-web-devicons
          persistence-nvim
          plenary-nvim
          snacks-nvim
          telescope-fzf-native-nvim
          telescope-nvim
          todo-comments-nvim
          tokyonight-nvim
          trouble-nvim
          ts-comments-nvim
          which-key-nvim
          vim-markdown-toc
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
          nvim-nio
          one-small-step-for-vimkind
          none-ls-nvim
          markdown-preview-nvim
          render-markdown-nvim
          image-nvim
          hover-nvim

          # Python
          neotest-python
          nvim-dap-python

          # C#
          omnisharp-extended-lsp-nvim
          neotest-dotnet

          # Cmake
          cmake-tools-nvim
          SchemaStore-nvim

          {
            name = "LuaSnip";
            path = luasnip;
          }

          {
            name = "catppuccin";
            path = catppuccin-nvim;
          }
          {
            name = "mini.ai";
            path = mini-nvim;
          }
          {
            name = "mini.bufremove";
            path = mini-nvim;
          }
          {
            name = "mini.comment";
            path = mini-nvim;
          }
          {
            name = "mini.indentscope";
            path = mini-nvim;
          }
          {
            name = "mini.pairs";
            path = mini-nvim;
          }
          {
            name = "mini.surround";
            path = mini-nvim;
          }
        ];
        mkEntryFromDrv =
          drv:
          if lib.isDerivation drv then
            {
              name = "${lib.getName drv}";
              path = drv;
            }
          else
            drv;

        lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
      in
      ''
        require("lazy").setup({
          defaults = {
            lazy = true,
          },
          dev = {
            -- reuse files from pkgs.vimPlugins.*
            path = "${lazyPath}",
            patterns = { "" },
            -- fallback to download
            fallback = true,
          },
          spec = {
            { "LazyVim/LazyVim", import = "lazyvim.plugins" },
            -- The following configs are needed for fixing lazyvim on nix
            -- force enable telescope-fzf-native.nvim
            { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },

            { import = "lazyvim.plugins.extras.coding.blink" },
            { import = "lazyvim.plugins.extras.coding.luasnip" },
            { import = "lazyvim.plugins.extras.coding.mini-surround" },
            { import = "lazyvim.plugins.extras.coding.yanky" },
            { import = "lazyvim.plugins.extras.coding.neogen" },
            { import = "lazyvim.plugins.extras.dap.core" },
            { import = "lazyvim.plugins.extras.dap.nlua" },
            { import = "lazyvim.plugins.extras.editor.dial" },
            -- { import = "lazyvim.plugins.extras.formatting.biome" },
            { import = "lazyvim.plugins.extras.formatting.black" },
            { import = "lazyvim.plugins.extras.formatting.prettier" },
            { import = "lazyvim.plugins.extras.lang.cmake" },
            { import = "lazyvim.plugins.extras.lang.docker" },
            { import = "lazyvim.plugins.extras.lang.git" },
            { import = "lazyvim.plugins.extras.lang.json" },
            { import = "lazyvim.plugins.extras.lang.nix" },
            { import = "lazyvim.plugins.extras.lang.go" },
            { import = "lazyvim.plugins.extras.lang.zig" },
            { import = "lazyvim.plugins.extras.lang.markdown" },
            { import = "lazyvim.plugins.extras.lang.nushell" },
            { import = "lazyvim.plugins.extras.lang.omnisharp" },
            { import = "lazyvim.plugins.extras.lang.clangd" },
            -- { import = "lazyvim.plugins.extras.lang.vue" },
            { import = "lazyvim.plugins.extras.lang.typescript" },
            { import = "lazyvim.plugins.extras.lang.python" },
            { import = "lazyvim.plugins.extras.lang.rust" },
            { import = "lazyvim.plugins.extras.lang.tailwind" },
            { import = "lazyvim.plugins.extras.lang.toml" },
            { import = "lazyvim.plugins.extras.lang.yaml" },
            { import = "lazyvim.plugins.extras.linting.eslint" },
            { import = "lazyvim.plugins.extras.ui.alpha" },
            -- { import = "lazyvim.plugins.extras.ui.edgy" },
            { import = "lazyvim.plugins.extras.ui.mini-animate" },
            { import = "lazyvim.plugins.extras.ui.mini-indentscope" },
            { import = "lazyvim.plugins.extras.ui.smear-cursor" },
            { import = "lazyvim.plugins.extras.ui.treesitter-context" },
            { import = "lazyvim.plugins.extras.util.dot" },
            { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
            { import = "lazyvim.plugins.extras.util.project" },
            { import = "lazyvim.plugins.extras.util.rest" },
            { import = "lazyvim.plugins.extras.editor.telescope" },
            { import = "lazyvim.plugins.extras.editor.refactoring" },
            { import = "lazyvim.plugins.extras.editor.harpoon2" },

            -- uncomment to import/override with your plugins
            { import = "plugins" },

            -- Vue & Typescript
            {
              "neovim/nvim-lspconfig",
              opts = function(_, opts)
                table.insert(opts.servers.vtsls.filetypes, "vue")
                LazyVim.extend(opts.servers.vtsls, "settings.vtsls.tsserver.globalPlugins", {
                  {
                    name = "@vue/typescript-plugin",
                    location = "${pkgs.vue-language-server}/lib/node_modules/@vue/language-server",
                    languages = { "vue" },
                    configNamespace = "typescript",
                    enableForWorkspaceTypeScriptVersions = true,
                  },
                })
              end
            },

            -- Nix
            {
              "neovim/nvim-lspconfig",
              opts = {
                servers = {
                  nixd = {
                    cmd = { "nixd" },
                    filetypes = { "nix" },
                    single_file_support = true,
                    root_dir = function(fname)
                      return require("lspconfig.util").root_pattern("flake.nix")(fname)
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
                            expr = '(builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations.${device-name}.options',
                          },
                          home_manager = {
                            expr = '(builtins.getFlake ("git+file://" + toString ./.)).homeConfigurations."${username}@${device-name}".options',
                          }
                        }
                      }
                    }
                  }
                }
              }
            },

            -- disable DAP
            { "mfussenegger/nvim-dap-python", enabled = false },
            { "mfussenegger/nvim-dap", enabled = false },

            -- disable mason.nvim, use config.extraPackages
            { "williamboman/mason-lspconfig.nvim", enabled = false },
            { "williamboman/mason.nvim", enabled = false },
            { "jay-babu/mason-nvim-dap.nvim", enabled = false },

            -- put this line at the end of spec to clear ensure_installed
            { "nvim-treesitter/nvim-treesitter", opts = function(_, opts) opts.ensure_installed = {} end },
          },
        })
      '';
  };

  xdg.configFile."nvim/parser".source =
    let
      parsers = pkgs.symlinkJoin {
        name = "treesitter-parsers";
        paths =
          (pkgs.vimPlugins.nvim-treesitter.withPlugins (
            plugins: with plugins; [
              c
              cpp
              c_sharp
              lua
              bash
              comment
              css
              scss
              nu
              ninja
              rst

              # rust
              rust
              ron

              # docker
              dockerfile

              fish

              # cmake
              cmake

              # git
              gitattributes
              gitignore
              git_config
              gitcommit
              git_rebase

              go
              gomod
              gowork
              gosum

              hcl
              javascript
              jq
              json5
              lua
              make
              markdown
              nix
              python
              toml
              typescript
              vue
              yaml
              zig
            ]
          )).dependencies;
      };
    in
    "${parsers}/parser";

  xdg.configFile."nvim/lua".source = ../config/nvim/lua;
}
