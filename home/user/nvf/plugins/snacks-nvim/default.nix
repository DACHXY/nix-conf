{ pkgs, ... }:
let
  tex = pkgs.texliveFull.withPackages (
    ps: with ps; [
      standalone
      everysel
      preview
      doublestroke
      msg
      setspace
      rsfs
      relsize
      ragged2e
      fundus-calligra
      microtype
      wasysym
      physics
      dvisvgm
      jknapltx
      wasy
      cm-super
      dvisvgm
      amstex
      babel-english
      amsmath
      amsfonts
      mathtools
      amscdx
      xcolor
    ]
  );
in
{
  programs.nvf.settings.vim = {
    keymaps = import ./keymaps.nix;
    extraPackages = with pkgs; [
      fd
      imagemagick
      ghostscript
      tex
    ];
  };

  programs.nvf.settings.vim.utility.snacks-nvim = {
    enable = true;
    setupOpts = {
      image = {
        enabled = false;
        doc = {
          enabled = true;
        };
        math = {
          enabled = true;
          latex = {
            font_size = "Large";
            packages = [
              "amsmath"
              "amssymb"
              "amsfonts"
              "amscd"
              "mathtools"
            ];
          };
        };
      };
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
