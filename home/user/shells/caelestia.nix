{
  pkgs,
  lib,
  osConfig,
  config,
  ...
}:
let
  inherit (lib) mkForce hasAttr;
  prefix = if osConfig.hardware.nvidia.prime.offload.enableOffloadCmd then "nvidia-offload " else "";
  terminal = "${prefix}ghostty";
  explorer = "nautilus";
in
{
  # ==== Disabled Services ==== #
  services.swww.enable = mkForce false;
  programs.waybar.enable = mkForce false;
  services.swaync.enable = mkForce false;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig.enable = true;

  # programs.niri.settings = with config.lib.niri.actions; {
  #   binds = {
  #     "Alt+Space".action = mkForce (spawn "caelestia" "shell" "drawers" "toggle" "launcher");
  #   };
  # };

  programs.caelestia = {
    enable = true;
    systemd.environment = [
      "QT_QPA_PLATFORMTHEME=gtk3"
    ];
    settings = {
      paths.wallpaperDir = "~/Pictures/Wallpapers";
      general.apps = {
        terminal = [ terminal ];
        explorer = [ explorer ];
      };
      visualiser.enabled = true;
      osd.hideDelay = 1500;
      utilities.vpn = {
        enabled = hasAttr "wg-quick-wg0" osConfig.systemd.services;
        provider = [
          {
            name = "wireguard";
            interface = "wg0";
            displayName = "Wireguard (DN)";
          }
        ];
      };
    };
    cli = {
      enable = true;
      settings = {
      };
    };
  };

  gtk = {
    enable = true;
    iconTheme = mkForce {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

}
