{
  config,
  pkgs,
  lib,
  ...
}:
let
  caelestiaDot = pkgs.fetchFromGitHub {
    owner = "caelestia-dots";
    repo = "caelestia";
    rev = "main";
    sha256 = "sha256-pRLcbh81iBp9fH3Zq7HrNtAfDD46ErGZ3wID8Q65Wlg=";
  };
in
{
  home.packages = with pkgs; [
    cliphist
    inotify-tools
    app2unit
    wireplumber
    trash-cli
    foot
    fastfetch
    jq
    socat
    imagemagick
    papirus-icon-theme
    nerd-fonts.jetbrains-mono
    fuzzel
  ];

  xdg.configFile = {
    "hypr/hyprland".source = "${caelestiaDot}/hypr/hyprland";
    "hypr/scheme" = {
      source = "${caelestiaDot}/hypr/scheme";
      recursive = true;
    };
    "hypr/scripts" = {
      source = "${caelestiaDot}/hypr/scripts";
      executable = true;
    };
    "hypr/variables.conf".source = "${caelestiaDot}/hypr/variables.conf";
  };

  wayland.windowManager.hyprland = {
    settings = {
      "$hypr" = "~/.config/hypr";
      "$hl" = "$hypr/hyprland";
      "$cConf" = "~/.config/caelestia";
      # ### Hyprland ###
      # Apps
      "$terminal" = "ghostty";
      "$browser" = "nvidia-offload zen";
      "$editor" = "nvim";
      "$fileExplorer" = "yazi";

      # Touchpad
      "$touchpadDisableTyping" = "true";
      "$touchpadScrollFactor" = "0.3";
      "$workSpaceSwipeFingers" = "4";

      # Blur
      "$blurEnabled" = "true";
      "$blurSpecialWs" = "false";
      "$blurPopups" = "true";
      "$blurInputMethods" = "true";
      "$blurSize" = "8";
      "$blurPasses" = "2";
      "$blurXray" = "false";

      # Shadow
      "$shadowEnabled" = "true";
      "$shadowRange" = "20";
      "$shadowRenderPower" = "3";
      "$shadowColour" = "rgba($surfaced4)";

      # Gaps
      "$workspaceGaps" = "20";
      "$windowGapsIn" = "10";
      "$windowGapsOut" = "10";
      "$singleWindowGapsOut" = "10";

      # Window styling
      "$windowOpacity" = "0.95";
      "$windowRounding" = "10";

      "$windowBorderSize" = "3";
      "$activeWindowBorderColour" = "rgba($primarye6)";
      "$inactiveWindowBorderColour" = "rgba($onSurfaceVariant11)";

      # Misc
      "$volumeStep" = "5 # In percent";

      "$kbGoToWs" = "SUPER";
      "$wsaction" = "~/.config/hypr/scripts/wsaction.fish";

      source = [
        "$hypr/scheme/current.conf"
        "$hl/env.conf"
        "$hl/input.conf"
        "$hl/misc.conf"
        "$hl/animations.conf"
        "$hl/decoration.conf"
        "$hl/group.conf"
        "$hl/rules.conf"
        "${pkgs.writeText "keybinds.conf" ''
          exec = hyprctl dispatch submap global
          submap = global

          # ## Shell keybinds
          # Launcher
          bind = Super+CTRL, K, global, caelestia:showall
          bindi = Super, Super_L, global, caelestia:launcher
          bindin = Super, catchall, global, caelestia:launcherInterrupt
          bindin = Super, mouse:272, global, caelestia:launcherInterrupt
          bindin = Super, mouse:273, global, caelestia:launcherInterrupt
          bindin = Super, mouse:274, global, caelestia:launcherInterrupt
          bindin = Super, mouse:275, global, caelestia:launcherInterrupt
          bindin = Super, mouse:276, global, caelestia:launcherInterrupt
          bindin = Super, mouse:277, global, caelestia:launcherInterrupt
          bindin = Super, mouse_up, global, caelestia:launcherInterrupt
          bindin = Super, mouse_down, global, caelestia:launcherInterrupt
          bind = Super, DELETE, global, caelestia:lock
          bind = Super, Q, killactive,
          bind = Super , RETURN, exec, app2unit -- $terminal
          bind = Super, F, exec, app2unit -- $browser
          bind = Super, V, togglefloating,
          bind = Super, P, pseudo
          bind = Super, S, togglesplit
          bindl = , XF86AudioPlay, global, caelestia:mediaToggle
          bindl = , XF86AudioPause, global, caelestia:mediaToggle
          bindl = , XF86AudioNext, global, caelestia:mediaNext
          bindl = , XF86AudioPrev, global, caelestia:mediaPrev
          bindl = , XF86AudioStop, global, caelestia:mediaStop

          bind = Super+SHIFT, s, global, caelestia:screenshot
          bind = CTRL SHIFT, s, exec, hyprshot -m window
          bind = CTRL SHIFT Super, s, exec, hyprshot -m output
          bind = CTRL ALT, s, exec, hyprshot -m active -m window

          bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
          bindle = , XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ $volumeStep%+
          bindle = , XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ $volumeStep%-

          bind = Super, Period, exec, pkill fuzzel || caelestia emoji -p
          bind = Super+Shift, V, exec, pkill fuzzel || caelestia clipboard
        ''}"
      ];

      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        ''SUPER, mouse:272, movewindow''
        ''SUPER, mouse:273, resizewindow''
      ];

      exec = [
        "cp -L --no-preserve=mode --update=none $hypr/scheme/default.conf $hypr/scheme/current.conf"
      ];

      misc = {
        vrr = 0;
        vfr = true;
      };
    };
  };

  home.activation.writeConfigFile =
    lib.hm.dag.entryAfter [ "writeBoundary" ]
      # bash
      ''
        configList=("btop" "fastfetch" "thunar")

        for config in "''\${configList[@]}"; do
          if [ ! -d "$XDG_CONFIG_HOME/$config" ]; then
            install -Dm666 "${caelestiaDot}/$config" "$XDG_CONFIG_HOME/$config"
          fi
        done
      '';

  fonts.fontconfig.enable = true;

  programs.caelestia = {
    enable = true;
    settings = { };
    cli = {
      enable = true;
      settings = { };
    };
  };

  systemd.user.services.caelestia = {
    Service = {
      Environment = [
        "QT_QPA_PLATFORMTHEME=gtk3"
      ];
    };
  };

  services.swww.enable = lib.mkForce false;
  programs.waybar.enable = lib.mkForce false;
  services.swaync.enable = lib.mkForce false;
}
