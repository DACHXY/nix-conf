{ lib }:
let
  inherit (lib) mkForce;
in
{
  capsuleOpacity = mkForce 0;
  backgroundOpacity = mkForce 0.25;
  autoHideDelay = 500;
  autoShowDelay = 150;
  barType = "floating";
  capsuleColorKey = "none";
  contentPadding = 2;
  density = "comfortable";
  displayMode = "always_visible";
  floating = true;
  fontScale = 1;
  frameRadius = 12;
  frameThickness = 8;
  hideOnOverview = false;
  marginHorizontal = 5;
  marginVertical = 5;
  middleClickAction = "none";
  middleClickCommand = "";
  middleClickFollowMouse = false;
  monitors = [ ];
  mouseWheelAction = "none";
  mouseWheelWrap = true;
  outerCorners = false;
  position = "top";
  reverseScroll = false;
  rightClickAction = "controlCenter";
  rightClickCommand = "";
  rightClickFollowMouse = true;
  screenOverrides = [ ];
  showCapsule = true;
  showOnWorkspaceSwitch = true;
  showOutline = false;
  useSeparateOpacity = false;
  widgetSpacing = 6;
  widgets = {
    center = [
      {
        defaultSettings = {
          activeColor = "primary";
          enableToast = true;
          hideInactive = false;
          iconSpacing = 4;
          inactiveColor = "none";
          micFilterRegex = "";
          removeMargins = false;
        };
        id = "plugin:privacy-indicator";
      }
      {
        colorizeIcons = false;
        hideMode = "hidden";
        id = "ActiveWindow";
        maxWidth = 145;
        scrollingMode = "hover";
        showIcon = true;
        textColor = "none";
        useFixedWidth = false;
      }
    ];
    left = [
      {
        colorizeSystemIcon = "none";
        enableColorization = false;
        generalTooltipText = "";
        hideMode = "alwaysExpanded";
        icon = "rocket";
        id = "CustomButton";
        ipcIdentifier = "";
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
        showExecTooltip = true;
        showIcon = true;
        showTextTooltip = true;
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
      { id = "plugin:weekly-calendar"; }
      {
        clockColor = "none";
        customFont = "";
        formatHorizontal = "HH:mm ddd, MMM dd";
        formatVertical = "HH mm - dd MM";
        id = "Clock";
        tooltipFormat = "HH:mm ddd, MMM dd";
        useCustomFont = false;
      }
      {
        characterCount = 4;
        colorizeIcons = false;
        emptyColor = "secondary";
        enableScrollWheel = true;
        focusedColor = "primary";
        followFocusedScreen = false;
        fontWeight = "bold";
        groupedBorderOpacity = 1;
        hideUnoccupied = false;
        iconScale = 0.8;
        id = "Workspace";
        labelMode = "index";
        occupiedColor = "secondary";
        pillSize = 0.6;
        showApplications = false;
        showBadge = true;
        showLabelsOnlyWhenOccupied = true;
        unfocusedIconsOpacity = 1;
      }
      {
        compactMode = false;
        hideMode = "hidden";
        hideWhenIdle = false;
        id = "MediaMini";
        maxWidth = 250;
        panelShowAlbumArt = true;
        scrollingMode = "hover";
        showAlbumArt = true;
        showArtistFirst = false;
        showProgressRing = true;
        showVisualizer = true;
        textColor = "none";
        useFixedWidth = false;
        visualizerType = "linear";
      }
    ];
    right = [
      {
        blacklist = [ "Bluetooth*" ];
        chevronColor = "none";
        colorizeIcons = false;
        drawerEnabled = false;
        hidePassive = false;
        id = "Tray";
        pinned = [ ];
      }
      {
        compactMode = true;
        diskPath = "/";
        iconColor = "none";
        id = "SystemMonitor";
        showCpuCores = false;
        showCpuFreq = false;
        showCpuTemp = true;
        showCpuUsage = true;
        showDiskAvailable = false;
        showDiskUsage = false;
        showDiskUsageAsPercent = false;
        showGpuTemp = false;
        showLoadAverage = false;
        showMemoryAsPercent = false;
        showMemoryUsage = true;
        showNetworkStats = false;
        showSwapUsage = false;
        textColor = "none";
        useMonospaceFont = true;
        usePadding = false;
      }
      {
        defaultSettings = {
          connectedColor = "primary";
          disconnectedColor = "none";
          displayMode = "onhover";
        };
        id = "plugin:network-manager-vpn";
      }
      {
        defaultSettings = {
          compactMode = false;
          defaultPeerAction = "copy-ip";
          hideDisconnected = false;
          pingCount = 5;
          refreshInterval = 5000;
          showIpAddress = true;
          showPing = false;
        };
        id = "plugin:netbird";
      }
      {
        defaultSettings = {
          audioCodec = "opus";
          audioSource = "default_output";
          colorRange = "limited";
          copyToClipboard = false;
          directory = "";
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
      {
        iconColor = "none";
        id = "KeepAwake";
        textColor = "none";
      }
      {
        defaultSettings = {
          completedCount = 0;
          count = 0;
          current_page_id = 0;
          exportEmptySections = false;
          exportFormat = "markdown";
          exportPath = "~/Documents";
          isExpanded = false;
          pages = [
            {
              id = 0;
              name = "General";
            }
          ];
          priorityColors = {
            high = "#f44336";
            low = "#9e9e9e";
            medium = "#2196f3";
          };
          showBackground = true;
          showCompleted = true;
          todos = [ ];
          useCustomColors = false;
        };
        id = "plugin:todo";
      }
      {
        displayMode = "onhover";
        iconColor = "none";
        id = "Volume";
        middleClickCommand = "pwvucontrol || pavucontrol";
        textColor = "none";
      }
      {
        displayMode = "onhover";
        iconColor = "none";
        id = "Bluetooth";
        textColor = "none";
      }
      {
        hideWhenZero = true;
        hideWhenZeroUnread = false;
        iconColor = "none";
        id = "NotificationHistory";
        showUnreadBadge = true;
        unreadBadgeColor = "primary";
      }
      {
        deviceNativePath = "__default__";
        displayMode = "graphic-clean";
        hideIfIdle = true;
        hideIfNotDetected = true;
        id = "Battery";
        showNoctaliaPerformance = false;
        showPowerProfiles = false;
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
