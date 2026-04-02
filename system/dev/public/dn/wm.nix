{ config, pkgs, ... }:
let
  inherit (config.systemConf) username;
in
{
  home-manager.users."${username}" =
    { ... }:
    {
      # ==== Niri ==== #
      programs.niri.settings = {
        input.keyboard.xkb = {
          layout = "us";
          options = "caps:escape";
        };
        workspaces."game" = { };
        window-rules = [
          # Steam Game Fullscreen
          {
            matches = [
              {
                app-id = "^steam_app_(.*)$";
                title = "^.+$";
                is-floating = false;
              }
            ];
            open-fullscreen = true;
          }
          # Steam & Steam Game
          {
            matches = [
              { app-id = "^steam_app_*"; }
              { app-id = "^pioneergame.exe$"; }
              {
                app-id = "^steam$";
                title = "^Steam$";
              }
            ];
            open-on-workspace = "game";
          }
          {
            matches = [
              { app-id = "^steam$"; }
              { title = "^Steam Big Picture Mode$"; }
            ];
            open-floating = false;
          }
          # Steam Dialog float
          {
            matches = [
              { app-id = "^steam$"; }
              { title = "(.*)(EasyAntiCheat_EOS_Setup)(.*)"; }
              {
                app-id = "^pioneergame.exe$";
                title = "^$";
              }
            ];
            excludes = [
              {
                title = "^Steam$";
              }
            ];
            open-floating = true;
          }
        ];
      };

      # ==== Noctalia === #
      programs.noctalia-shell = {
        pluginSettings = {
          custom-commands =
            let
              toggleVPNScript = pkgs.writeShellScript "toggle-vpn" ''
                VPN_NAME="$*"

                if nmcli -t -f NAME connection show --active | grep -Fxq "$VPN_NAME"; then
                  nmcli connection down "$VPN_NAME"
                  notify-send "$VPN_NAME" "$VPN_NAME has been deactivated."
                else
                  nmcli connection up "$VPN_NAME"
                  notify-send "$VPN_NAME" "$VPN_NAME has been actived."
                fi
              '';
              toggleVPN = vpnName: "${toggleVPNScript} \"${vpnName}\"";
            in
            {
              commands = [
                rec {
                  name = "CSIT VPN";
                  command = toggleVPN name;
                  icon = "shield";
                }
                rec {
                  name = "CSIT VPN (test)";
                  command = toggleVPN name;
                  icon = "shield-code";
                }
              ];
            };
        };
      };

      wayland.windowManager.mango.settings = ''
        xkb_rules_options = caps:escape
      '';
    };
}
