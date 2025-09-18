{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    keymaps = import ./keymaps.nix;
    extraPackages = with pkgs; [ fd ];
  };

  programs.nvf.settings.vim.utility.snacks-nvim = {
    enable = true;
    setupOpts = {
      bigfile = {
        enabled = true;
      };
      dashboard = {
        enabled = false;
      };
      explorer = {
        enabled = true;
      };
      indent = {
        enabled = true;
      };
      input = {
        enabled = true;
      };
      picker = {
        enabled = true;
        sources = {
          explorer.layout.layout.position = "right";
        };
        formatters = {
          file.filename_first = true;
        };
      };
      notifier = {
        enabled = true;
      };
      quickfile = {
        enabled = true;
      };
      scope = {
        enabled = true;
      };
      scroll = {
        enabled = true;
      };
      statuscolumn = {
        enabled = false;
      };
      words = {
        enabled = true;
      };
    };
  };
}
