{pkgs, ...}: let
  snacksBinds = import ../binds/snacks.nix;
  logo = ''
     ██████████     █████████     █████████  █████   █████ █████ █████ █████ █████
    ░░███░░░░███   ███░░░░░███   ███░░░░░███░░███   ░░███ ░░███ ░░███ ░░███ ░░███
     ░███   ░░███ ░███    ░███  ███     ░░░  ░███    ░███  ░░███ ███   ░░███ ███
     ░███    ░███ ░███████████ ░███          ░███████████   ░░█████     ░░█████
     ░███    ░███ ░███░░░░░███ ░███          ░███░░░░░███    ███░███     ░░███
     ░███    ███  ░███    ░███ ░░███     ███ ░███    ░███   ███ ░░███     ░███
     ██████████   █████   █████ ░░█████████  █████   █████ █████ █████    █████
    ░░░░░░░░░░   ░░░░░   ░░░░░   ░░░░░░░░░  ░░░░░   ░░░░░ ░░░░░ ░░░░░    ░░░░░
  '';
in {
  "${pkgs.vimPlugins.snacks-nvim.pname}" = {
    enabled = true;
    priority = 1000;
    package = pkgs.vimPlugins.snacks-nvim;
    setupModule = "snacks";
    lazy = false;
    setupOpts = {
      animate.enabled = true;
      dashboard = {
        enabled = true;
        header = logo;
        keys = [
          {
            icon = " ";
            key = "f";
            desc = "Find File";
            action = ":lua Snacks.dashboard.pick('files')";
          }
          {
            icon = " ";
            key = "n";
            desc = "New File";
            action = ":ene | startinsert";
          }
          {
            icon = " ";
            key = "g";
            desc = "Find Text";
            action = ":lua Snacks.dashboard.pick('live_grep')";
          }
          {
            icon = " ";
            key = "r";
            desc = "Recent Files";
            action = ":lua Snacks.dashboard.pick('oldfiles')";
          }
          {
            icon = " ";
            key = "c";
            desc = "Config";
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})";
          }
          {
            icon = " ";
            key = "s";
            desc = "Restore Session";
            section = "session";
          }
          {
            icon = " ";
            key = "x";
            desc = "Lazy Extras";
            action = ":LazyExtras";
          }
          {
            icon = "󰒲 ";
            key = "l";
            desc = "Lazy";
            action = ":Lazy";
          }
          {
            icon = " ";
            key = "q";
            desc = "Quit";
            action = ":qa";
          }
        ];
      };
      indent.enabled = true;
      input.enabled = true;
      notifier.enabled = false;
      quickfile.enabled = true;
      scroll.enabled = true;
      statuscolumn.enabled = false;
      words.enabled = true;
    };

    keys = snacksBinds;
  };
}
