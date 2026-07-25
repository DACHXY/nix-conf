{ inputs, ... }:
let
  commonAliases = {
    ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";
    ls = "exa --icons auto";
    lp = "exa"; # Pure output
    cat = "bat";
    g = "git";
    t = "tmux";
    podt = "podman-tui";
    ds = "devenv shell";

    # Nixos
    fullClean = "sudo nix store gc && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";
  };
in
{
  flake.modules.generic.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkDefault;
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      environment.variables = {
        EDITOR = "nvim";
        SHELL = "/run/current-system/sw/bin/fish";
      };

      environment.systemPackages = with pkgs; [
        inputs.nix-search-tv.packages.${system}.default
        eza
        bat
      ];

      programs.zsh.enable = mkDefault true;

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set fish_greeting # Disable greeting

          # ==== Prevent Running Everything on GPU ==== #
          set -e __NV_PRIME_RENDER_OFFLOAD
          set -e __NV_PRIME_RENDER_OFFLOAD_PROVIDER
          set -e __GLX_VENDOR_LIBRARY_NAME
          set -e __VK_LAYER_NV_optimus
        '';
        shellAliases = commonAliases;
      };
    };

  flake.modules.darwin.base =
    { pkgs, config, ... }:
    let
      hostname = config.networking.hostName;
      rebuild = pkgs.writeShellScriptBin "rebuild" ''
        nh darwin switch . -H "${hostname}" --accept-flake-config $@
      '';
    in
    {
      # ==== Make Default Interactive Shell to fish ==== #
      programs.zsh.interactiveShellInit = ''
        if [[ "$(${pkgs.procps}/bin/ps -o comm= -p $PPID)" != "fish" ]] \
          && [[ -z "$BASH_EXECUTION_STRING" ]]
        then
          [[ -o login ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';

      environment.systemPackages = with pkgs; [
        rebuild
        grc
      ];

      home-manager.users.${config.my.user.name} = {
        home.file.".hushlogin".text = "";
      };
    };

  flake.modules.nixos.base =
    { pkgs, config, ... }:
    let
      hostname = config.networking.hostName;
      rebuild = pkgs.writeShellScriptBin "rebuild" ''
        nh os switch . -H "${hostname}" --accept-flake-config $@
      '';
    in
    {
      environment.systemPackages = with pkgs; [
        rebuild
        grc
      ];

      programs = {
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
        mtr.enable = true;

        fish.shellAliases = {
          # Systemd Boot
          setWin = "sudo bootctl set-oneshot auto-windows";
          goWin = "sudo bootctl set-oneshot auto-windows && reboot";
          goBios = "sudo bootctl set-oneshot auto-reboot-to-firmware-setup && reboot";

          # TTY
          hideTTY = ''sudo sh -c "echo 0 > /sys/class/graphics/fb0/blank"'';
          showTTY = ''sudo sh -c "echo 1 > /sys/class/graphics/fb0/blank"'';

          # Trash cli
          rm = "trash";
        };
      };

      home-manager.users.${config.my.user.name} = {
        # Set fish as default shell but not login shell
        programs.bash = {
          enable = true;
          initExtra = ''
            if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
            then
              shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
              exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
            fi
          '';
        };
      };
    };

  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

      programs.wshowkeys = {
        enable = true;
        package = inputs.wshowkeys.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };

      programs.fish.shellAliases = {
        # Show keys
        showkeys = "wshowkeys -a bottom -F 'Sans Bold 30' -s '#B5B520ff' -f  '#ecd29cff' -b '#201B1488' -l 600 -t 500 -M -U -S";
      };
    };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      programs = {
        btop = {
          enable = true;
          settings = {
            theme_background = false;
            update_ms = 1000;
          };
        };

        fish = {
          enable = true;
          interactiveShellInit = ''
            set fish_greeting # Disable greeting

            # ==== Prevent Running Everything on GPU ==== #
            set -e __NV_PRIME_RENDER_OFFLOAD
            set -e __NV_PRIME_RENDER_OFFLOAD_PROVIDER
            set -e __GLX_VENDOR_LIBRARY_NAME
            set -e __VK_LAYER_NV_optimus
          '';
          plugins = [
            {
              name = "grc";
              src = pkgs.fishPlugins.grc.src;
            }
            {
              name = "fzf-fish";
              src = pkgs.fishPlugins.fzf-fish.src;
            }
            {
              name = "forgit";
              src = pkgs.fishPlugins.forgit.src;
            }
            {
              name = "hydro";
              src = pkgs.fishPlugins.hydro.src;
            }
          ];
        };

        carapace = {
          enable = true;
          enableFishIntegration = true;
        };

        starship = {
          enable = true;
          extraPackages = with pkgs; [ jj-starship ];
          enableFishIntegration = true;
          settings = {
            git_branch.disabled = true;
            git_status.disabled = true;
            custom.jj = {
              when = "jj-starship detect";
              shell = [ "jj-starship" ];
              format = "$output ";
            };
          };
        };

        zoxide = {
          enable = true;
          enableFishIntegration = true;
        };
      };
    };
}
