{ hostname }:
{ pkgs, ... }:
let
  username = "danny";
  domain = "dnywe.com";
  stateVersion = 6;
in
{
  imports = [
    ../../../options/systemconf.nix
    ./shell.nix
    ./nixsettings.nix
    ./packages.nix
    ./home
    ./homebrew.nix
    ./services
    ./font.nix
  ];

  systemConf = {
    inherit username hostname;
    domain = "dnywe.com";
  };

  networking = {
    hostName = hostname;
    domain = domain;
  };

  users.users.${username} = {
    name = "${username}";
    home = "/Users/${username}";
    isHidden = false;
    shell = pkgs.fish;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMT/rhCBp90SBW15dObrI1vl48uIdbjzwK+LQxtd/m8m danny@dn-workstation"
    ];
  };

  system = {
    inherit stateVersion;

    primaryUser = username;
    checks.verifyNixPath = false;
    defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleInterfaceStyleSwitchesAutomatically = false;
        AppleShowScrollBars = "Automatic";

        KeyRepeat = 2;
        InitialKeyRepeat = 15;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      # --- Login Window ---
      loginwindow = {
        GuestEnabled = false;
        SHOWFULLNAME = false;
      };

      # --- Screensaver & Lock ---
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0; # 0 = immediately
      };

      # --- Screenshots ---
      screencapture = {
        type = "png"; # png, jpg, gif, pdf, tiff
        disable-shadow = true;
        include-date = true;
      };

      # --- Control Center (Menu Bar) ---
      controlcenter = {
        BatteryShowPercentage = true;
        Bluetooth = true;
        Sound = true;
        Display = true;
        FocusModes = true;
        NowPlaying = true;
      };

      dock = {
        autohide = true;
        show-recents = false;
        launchanim = true;
        orientation = "bottom";
        tilesize = 30;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };
}
