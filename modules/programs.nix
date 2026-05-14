{ inputs, ... }:
{
  flake.modules.generic.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkDefault;
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
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
        shellAliases = {
          ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";
          ls = "exa --icons";
          lp = "exa"; # Pure output
          cat = "bat";
          g = "git";
          t = "tmux";
          podt = "podman-tui";

          # Nixos
          fullClean = "sudo nix store gc && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";
        };
      };
    };

  flake.modules.darwin.base =
    { pkgs, config, ... }:
    let
      hostname = config.networking.hostName;
      rebuild = pkgs.writeShellScriptBin "rebuild" ''
        nh darwin switch . -H "${hostname}"
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
        nh os switch . -H "${hostname}"
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
    };

  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];
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
          enableFishIntegration = true;
          settings = {
            palette = "catppuccin_macchiato";
            shell = {
              fish_indicator = "󰈺 ";
              powershell_indicator = ">_";
              unknown_indicator = "+>";
            };
            character = {
              success_symbol = "[(green) ❯](peach)";
              error_symbol = "[(red) ❯](peach)";
              vimcmd_symbol = "[ ❮](subtext1)";
            };
            git_branch = {
              style = "bold mauve";
              symbol = " ";
              format = "[$symbol$branch]($style)";
            };
            directory = {
              truncation_length = 4;
              style = "bold lavender";
              read_only = " 󰌾";
            };
            palettes = {
              catppuccin_latte = {
                rosewater = "#dc8a78";
                flamingo = "#dd7878";
                pink = "#ea76cb";
                mauve = "#8839ef";
                red = "#d20f39";
                maroon = "#e64553";
                peach = "#fe640b";
                yellow = "#df8e1d";
                green = "#40a02b";
                teal = "#179299";
                sky = "#04a5e5";
                sapphire = "#209fb5";
                blue = "#1e66f5";
                lavender = "#7287fd";
                text = "#4c4f69";
                subtext1 = "#5c5f77";
                subtext0 = "#6c6f85";
                overlay2 = "#7c7f93";
                overlay1 = "#8c8fa1";
                overlay0 = "#9ca0b0";
                surface2 = "#acb0be";
                surface1 = "#bcc0cc";
                surface0 = "#ccd0da";
                base = "#eff1f5";
                mantle = "#e6e9ef";
                crust = "#dce0e8";
              };
              catppuccin_frappe = {
                rosewater = "#f2d5cf";
                flamingo = "#eebebe";
                pink = "#f4b8e4";
                mauve = "#ca9ee6";
                red = "#e78284";
                maroon = "#ea999c";
                peach = "#ef9f76";
                yellow = "#e5c890";
                green = "#a6d189";
                teal = "#81c8be";
                sky = "#99d1db";
                sapphire = "#85c1dc";
                blue = "#8caaee";
                lavender = "#babbf1";
                text = "#c6d0f5";
                subtext1 = "#b5bfe2";
                subtext0 = "#a5adce";
                overlay2 = "#949cbb";
                overlay1 = "#838ba7";
                overlay0 = "#737994";
                surface2 = "#626880";
                surface1 = "#51576d";
                surface0 = "#414559";
                base = "#303446";
                mantle = "#292c3c";
                crust = "#232634";
              };
              catppuccin_macchiato = {
                rosewater = "#f4dbd6";
                flamingo = "#f0c6c6";
                pink = "#f5bde6";
                mauve = "#c6a0f6";
                red = "#ed8796";
                maroon = "#ee99a0";
                peach = "#f5a97f";
                yellow = "#eed49f";
                green = "#a6da95";
                teal = "#8bd5ca";
                sky = "#91d7e3";
                sapphire = "#7dc4e4";
                blue = "#8aadf4";
                lavender = "#b7bdf8";
                text = "#cad3f5";
                subtext1 = "#b8c0e0";
                subtext0 = "#a5adcb";
                overlay2 = "#939ab7";
                overlay1 = "#8087a2";
                overlay0 = "#6e738d";
                surface2 = "#5b6078";
                surface1 = "#494d64";
                surface0 = "#363a4f";
                base = "#24273a";
                mantle = "#1e2030";
                crust = "#181926";
              };
              catppuccin_mocha = {
                rosewater = "#f5e0dc";
                flamingo = "#f2cdcd";
                pink = "#f5c2e7";
                mauve = "#cba6f7";
                red = "#f38ba8";
                maroon = "#eba0ac";
                peach = "#fab387";
                yellow = "#f9e2af";
                green = "#a6e3a1";
                teal = "#94e2d5";
                sky = "#89dceb";
                sapphire = "#74c7ec";
                blue = "#89b4fa";
                lavender = "#b4befe";
                text = "#cdd6f4";
                subtext1 = "#bac2de";
                subtext0 = "#a6adc8";
                overlay2 = "#9399b2";
                overlay1 = "#7f849c";
                overlay0 = "#6c7086";
                surface2 = "#585b70";
                surface1 = "#45475a";
                surface0 = "#313244";
                base = "#1e1e2e";
                mantle = "#181825";
                crust = "#11111b";
              };
            };
            aws = {
              symbol = "  ";
              format = " [$symbol($profile)(\($region\))(\[$duration\])]($style)";
            };
            bun = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            c = {
              symbol = " ";
              format = " [$symbol($version(-$name))]($style)";
            };
            conda = {
              symbol = " ";
              format = " [$symbol$environment]($style)";
            };
            crystal = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            dart = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            docker_context = {
              symbol = " ";
              format = " [$symbol($version)(🎯 $tfm)]($style)";
            };
            elixir = {
              symbol = " ";
              format = " [$symbol($version \(OTP $otp_version\))]($style)";
            };
            elm = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            fennel = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            fossil_branch = {
              symbol = " ";
              format = " [$symbol$branch]($style)";
            };
            git_commit = {
              tag_symbol = "  ";
            };
            git_status = {
              format = " ([$ahead_behind$staged$modified$untracked$renamed$deleted$conflicted$stashed]($style)) ";
              conflicted = "[◪◦](italic bright-magenta)";
              ahead = "[▴│[''\${count}](bold white)│](italic green)";
              behind = "[▿│[''\${count}](bold white)│](italic red)";
              diverged = "[◇ ▴┤[''\${ahead_count}](regular white)│▿┤[''\${behind_count}](regular white)│](italic bright-magenta)";
              untracked = "[◌◦](italic bright-yellow)";
              stashed = "[◃◈](italic white)";
              modified = "[●◦](italic yellow)";
              staged = "[▪┤[$count](bold white)│](italic bright-cyan)";
              renamed = "[◎◦](italic bright-blue)";
              deleted = "[✕](italic red)";
            };
            golang = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            guix_shell = {
              symbol = " ";
              format = " [$symbol]($style)";
            };
            haskell = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            helm = {
              format = " [$symbol($version)]($style)";
            };
            haxe = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            hg_branch = {
              symbol = " ";
              format = " [$symbol$branch]($style)";
            };
            hostname = {
              ssh_symbol = " ";
            };
            java = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            julia = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            kotlin = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            kubernetes = {
              format = " [$symbol$context( \($namespace\))]($style)";
            };
            lua = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            memory_usage = {
              symbol = "󰍛 ";
              format = " $symbol[$ram( | $swap)]($style)";
            };
            meson = {
              symbol = "󰔷 ";
              format = " [$symbol$project]($style)";
            };
            nim = {
              symbol = "󰆥 ";
              format = " [$symbol($version)]($style)";
            };
            nix_shell = {
              symbol = " ";
              format = " [$symbol$state( \($name\))]($style)";
            };
            nodejs = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            ocaml = {
              symbol = " ";
              format = " [$symbol($version)(\($switch_indicator$switch_name\))]($style)";
            };
            os = {
              symbols = {
                Alpaquita = " ";
                Alpine = " ";
                AlmaLinux = " ";
                Amazon = " ";
                Android = " ";
                Arch = " ";
                Artix = " ";
                CentOS = " ";
                Debian = " ";
                DragonFly = " ";
                Emscripten = " ";
                EndeavourOS = " ";
                Fedora = " ";
                FreeBSD = " ";
                Garuda = "󰛓 ";
                Gentoo = " ";
                HardenedBSD = "󰞌 ";
                Illumos = "󰈸 ";
                Kali = " ";
                Linux = " ";
                Mabox = " ";
                Macos = " ";
                Manjaro = " ";
                Mariner = " ";
                MidnightBSD = " ";
                Mint = " ";
                NetBSD = " ";
                NixOS = " ";
                OpenBSD = "󰈺 ";
                openSUSE = " ";
                OracleLinux = "󰌷 ";
                Pop = " ";
                Raspbian = " ";
                Redhat = " ";
                RedHatEnterprise = " ";
                RockyLinux = " ";
                Redox = "󰀘 ";
                Solus = "󰠳 ";
                SUSE = " ";
                Ubuntu = " ";
                Unknown = " ";
                Void = " ";
                Windows = "󰍲 ";
              };
              format = " [$symbol]($style)";
            };
            dotnet = {
              format = " [$symbol($version)(🎯 $tfm)]($style)";
            };
            deno = {
              format = " [$symbol($version)]($style)";
            };
            package = {
              symbol = "󰏗 ";
              format = " [$symbol$version]($style)";
            };
            cmd_duration = {
              format = " [⏱ $duration]($style)";
            };
            cobol = {
              format = " [$symbol($version)]($style)";
            };
            daml = {
              format = " [$symbol($version)]($style)";
            };
            perl = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            php = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            pijul_channel = {
              symbol = " ";
              format = " [$symbol$channel]($style)";
            };
            pulumi = {
              format = " [$symbol$stack]($style)";
            };
            purescript = {
              format = " [$symbol($version)]($style)";
            };
            python = {
              symbol = " ";
              format = " [''\${symbol}''\${pyenv_prefix}(''\${version})(\($virtualenv\))]($style)";
            };
            erlang = {
              symbol = "󰟔 ";
              format = " [$symbol($version)]($style)";
            };
            ruby = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            rust = {
              symbol = "󱘗 ";
              format = " [$symbol($version)]($style)";
            };
            scala = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            spack = {
              format = " [$symbol$environment]($style)";
            };
            sudo = {
              format = " [as $symbol]($style)";
            };
            swift = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            zig = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            gradle = {
              symbol = " ";
              format = " [$symbol($version)]($style)";
            };
            time = {
              format = " [$time]($style)";
            };
            username = {
              format = " [$user]($style)";
            };
            vagrant = {
              format = " [$symbol($version)]($style)";
            };
            vlang = {
              format = " [$symbol($version)]($style)";
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
