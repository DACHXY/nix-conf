{
  backgroundOpacity = 0.25;
  capsuleOpacity = 0;
  density = "comfortable";
  exclusive = true;
  floating = true;
  marginHorizontal = 0.25;
  marginVertical = 0.25;
  outerCorners = false;
  position = "top";
  showCapsule = true;
  widgets = {
    center = [
      {
        colorizeIcons = false;
        hideMode = "hidden";
        id = "ActiveWindow";
        maxWidth = 145;
        scrollingMode = "hover";
        showIcon = true;
        useFixedWidth = false;
      }
    ];
    left = [
      {
        icon = "rocket";
        id = "CustomButton";
        leftClickExec = "noctalia-shell ipc call launcher toggle";
        leftClickUpdateText = false;
        maxTextLength = {
          horizontal = 10;
          vertical = 10;
        };
        middleClickExec = "";
        middleClickUpdateText = false;
        parseJson = false;
        rightClickExec = "";
        rightClickUpdateText = false;
        textCollapse = "";
        textCommand = "";
        textIntervalMs = 3000;
        textStream = false;
        wheelDownExec = "";
        wheelDownUpdateText = false;
        wheelExec = "";
        wheelMode = "unified";
        wheelUpExec = "";
        wheelUpUpdateText = false;
        wheelUpdateText = false;
      }
      {
        customFont = "";
        formatHorizontal = "HH:mm ddd, MMM dd";
        formatVertical = "HH mm - dd MM";
        id = "Clock";
        useCustomFont = false;
        usePrimaryColor = true;
      }
      {
        characterCount = 4;
        followFocusedScreen = false;
        hideUnoccupied = false;
        id = "Workspace";
        labelMode = "index";
      }
      {
        hideMode = "hidden";
        hideWhenIdle = false;
        id = "MediaMini";
        maxWidth = 250;
        scrollingMode = "hover";
        showAlbumArt = true;
        showArtistFirst = false;
        showProgressRing = true;
        showVisualizer = true;
        useFixedWidth = false;
        visualizerType = "linear";
      }
    ];
    right = [
      {
        blacklist = [
          "Bluetooth*"
        ];
        colorizeIcons = false;
        drawerEnabled = false;
        id = "Tray";
        pinned = [
        ];
      }
      {
        diskPath = "/";
        id = "SystemMonitor";
        showCpuTemp = true;
        showCpuUsage = true;
        showDiskUsage = false;
        showMemoryAsPercent = false;
        showMemoryUsage = true;
        showNetworkStats = false;
        usePrimaryColor = false;
      }
      {
        id = "ScreenRecorder";
      }
      {
        id = "KeepAwake";
      }
      {
        displayMode = "onhover";
        id = "Volume";
      }
      {
        displayMode = "onhover";
        id = "Brightness";
      }
      {
        displayMode = "onhover";
        id = "VPN";
      }
      {
        displayMode = "onhover";
        id = "Bluetooth";
      }
      {
        hideWhenZero = true;
        id = "NotificationHistory";
        showUnreadBadge = true;
      }
      {
        colorizeDistroLogo = false;
        colorizeSystemIcon = "primary";
        customIconPath = "";
        enableColorization = true;
        icon = "noctalia";
        id = "ControlCenter";
        useDistroLogo = true;
      }
    ];
  };
}
