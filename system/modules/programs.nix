{ pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    # neovim
    luajitPackages.lua
    lua51Packages.lua
    luajitPackages.luarocks
    luajitPackages.magick
    imagemagick
  ];

  programs = {
    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };

    neovim = {
      enable = true;
      configure = {
        customRC = ''
          set number
          set relativenumber
          set tabstop=2
          set shiftwidth=2
          set expandtab
          nnoremap <C-s> :w<CR>
        '';
      };
    };

    dconf.enable = true;
    zsh.enable = true;
    mtr.enable = true;
    fish = {
      enable = true;
      shellAliases = {
        "ns" = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";
      };
    };

    # Set fish as default shell but not login shell
    bash = {
      interactiveShellInit = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };
  };
}
