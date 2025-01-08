{ pkgs, ... }:

let
  treesitterWithGrammars = (
    pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
      p.bash
      p.comment
      p.css
      p.dockerfile
      p.fish
      p.gitattributes
      p.gitignore
      p.go
      p.gomod
      p.gowork
      p.hcl
      p.javascript
      p.jq
      p.json5
      p.json
      p.lua
      p.make
      p.markdown
      p.nix
      p.python
      p.rust
      p.toml
      p.typescript
      p.vue
      p.yaml
    ])
  );

  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = treesitterWithGrammars.dependencies;
  };
  configDir = ../config;
in
{
  # Other Lsp servers are defined in system/module/lsp.nix
  home.packages = with pkgs; [
    gh
    vue-language-server
    dockerfile-language-server-nodejs
    black
    prettierd
    javascript-typescript-langserver
    marksman
    tailwindcss-language-server
    ruff
    ruff-lsp
    pyright
    hadolint
    yaml-language-server
    nodePackages_latest.typescript
  ];

  programs.neovim = {
    enable = true;
    vimAlias = true;
    coc.enable = false;
    withNodeJs = true;

    plugins =
      [
        treesitterWithGrammars
      ]
      ++ (with pkgs.vimPlugins; [
        markdown-preview-nvim
      ]);
    extraPackages = [ pkgs.imagemagick ];
    extraLuaPackages = ps: with ps; [ magick ];
  };

  home.file."./.config/nvim" = {
    source = "${configDir}/nvim";
    recursive = true;
  };

  home.file."./.config/nvim/init.lua".text = ''
    require("config.lazy")
    vim.opt.runtimepath:append("${treesitter-parsers}")
  '';

  # Treesitter is configured as a locally developed module in lazy.nvim
  # we hardcode a symlink here so that we can refer to it in our lazy config
  home.file."./.local/share/nvim/nix/extras/" = {
    recursive = true;
    source = treesitterWithGrammars;
  };

}
