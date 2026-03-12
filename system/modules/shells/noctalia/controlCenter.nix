{ config }:
{
  cards = [
    {
      enabled = true;
      id = "profile-card";
    }
    {
      enabled = true;
      id = "shortcuts-card";
    }
    {
      enabled = true;
      id = "audio-card";
    }
    {
      enabled = true;
      id = "weather-card";
    }
    {
      enabled = true;
      id = "media-sysmon-card";
    }
  ];
  diskPath = "/";
  position = "bottom_center";
  shortcuts = {
    left = [
      { id = "Network"; }
      { id = "Bluetooth"; }
      { id = "WallpaperSelector"; }
      {
        defaultSettings = {
          audioCodec = "opus";
          audioSource = "default_output";
          colorRange = "limited";
          copyToClipboard = false;
          directory = "${config.home.homeDirectory}/Videos";
          filenamePattern = "recording_yyyyMMdd_HHmmss";
          frameRate = "60";
          hideInactive = false;
          iconColor = "none";
          quality = "very_high";
          resolution = "original";
          showCursor = true;
          videoCodec = "h264";
          videoSource = "portal";
        };
        id = "plugin:screen-recorder";
      }
    ];
    right = [
      { id = "Notifications"; }
      { id = "PowerProfile"; }
      { id = "KeepAwake"; }
      { id = "NightLight"; }
    ];
  };
}
