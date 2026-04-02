{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    concatStringsSep
    getExe
    dropEnd
    last
    mkEnableOption
    mapAttrs'
    nameValuePair
    splitString
    ;

  inherit (builtins) length;

  cfg = config.wm;
  bindCfg = cfg.keybinds;

  sep = bindCfg.separator;
  mod = bindCfg.mod;

  main-color = "#EBDBB2";
  secondary-color = "#24273A";

  mkHyprBind =
    keys:
    let
      len = length keys;
      prefix = if len > 1 then [ ] else [ "None" ];
      finalKeys = prefix ++ keys;
    in
    (concatStringsSep "+" (dropEnd 1 finalKeys)) + ",${last finalKeys}";

  mkBindOption =
    keys:
    let
      hypr-key = mkHyprBind keys;
    in
    mkOption {
      type = types.str;
      default = if bindCfg.hypr-type then hypr-key else (concatStringsSep sep keys);
    };

  mkGradientColorOption =
    {
      from ? main-color,
      to ? secondary-color,
      angle ? 45,
    }:
    {
      from = mkOption {
        type = types.str;
        default = from;
      };
      to = mkOption {
        type = types.str;
        default = to;
      };
      angle = mkOption {
        type = types.int;
        default = angle;
      };
    };

in
{
  options.wm = {
    exec-once = mkOption {
      type = with types; nullOr lines;
      default = null;
      apply = v: if v != null then pkgs.writeShellScript "exec-once" v else null;
    };
    app = {
      browser = {
        package = mkOption {
          type = with types; nullOr package;
          default = null;
        };
        name = mkOption {
          type = with types; nullOr package;
          default = null;
        };
      };
      terminal = {
        package = mkOption {
          type = with types; nullOr package;
          default = null;
        };
        name = mkOption {
          type = with types; nullOr str;
          default = null;
        };
        run = mkOption {
          type = with types; nullOr str;
          default = "${getExe cfg.terminal.package} -e ";
        };
      };
      file-browser = {
        package = mkOption {
          type = with types; nullOr package;
          default = null;
        };
        name = mkOption {
          type = with types; nullOr str;
          default = null;
        };
      };
    };
    window = {
      opacity = mkOption {
        type = types.float;
        default = 0.85;
      };
    };
    input = {
      keyboard = {
        repeat-delay = mkOption {
          type = types.int;
          default = 250;
        };
        repeat-rate = mkOption {
          type = types.int;
          default = 35;
        };
      };
    };
    border = {
      active = mkGradientColorOption { };
      inactive = mkGradientColorOption {
        from = secondary-color;
        to = secondary-color;
      };
      radius = mkOption {
        type = types.int;
        default = 12;
      };
    };
    keybinds = {
      mod = mkOption {
        type = types.str;
        default = "Mod";
      };
      separator = mkOption {
        type = types.str;
        default = "+";
      };
      hypr-type = mkEnableOption "hyprland-like bind syntax" // {
        default = false;
      };

      spawn = mkOption {
        type = types.attrs;
        default = {
          "${mod}${sep}ENTER" = "${getExe cfg.app.terminal.package}";
          "${mod}${sep}F" = "${getExe cfg.app.browser.package}";
        };
        apply =
          binds:
          let
            hypr-binds = mapAttrs' (n: v: nameValuePair (mkHyprBind (splitString sep n)) v) binds;
          in
          if bindCfg.hypr-type then hypr-binds else binds;
      };

      spawn-repeat = mkOption {
        type = types.attrs;
        default = { };
        apply =
          binds:
          let
            hypr-binds = mapAttrs' (n: v: nameValuePair (mkHyprBind (splitString sep n)) v) binds;
          in
          if bindCfg.hypr-type then hypr-binds else binds;
      };

      # ==== Movement ==== #
      switch-window-focus = mkBindOption [
        mod
        "TAB"
      ];
      move-window-focus = {
        left = mkBindOption [
          mod
          "H"
        ];
        right = mkBindOption [
          mod
          "L"
        ];
        up = mkBindOption [
          mod
          "K"
        ];
        down = mkBindOption [
          mod
          "J"
        ];
      };
      move-monitor-focus = {
        left = mkBindOption [
          mod
          "CTRL"
          "H"
        ];
        right = mkBindOption [
          mod
          "CTRL"
          "L"
        ];
      };
      move-workspace-focus = {
        # Workspace Focus
        next = mkBindOption [
          mod
          "CTRL"
          "J"
        ];
        prev = mkBindOption [
          mod
          "CTRL"
          "k"
        ];
      };
      move-window = {
        left = mkBindOption [
          mod
          "SHIFT"
          "H"
        ];
        right = mkBindOption [
          mod
          "SHIFT"
          "L"
        ];
        up = mkBindOption [
          mod
          "SHIFT"
          "K"
        ];
        down = mkBindOption [
          mod
          "SHIFT"
          "J"
        ];
      };

      consume-window = {
        left = mkBindOption [
          mod
          "CTRL"
          "SHIFT"
          "H"
        ];
        right = mkBindOption [
          mod
          "CTRL"
          "SHIFT"
          "L"
        ];
      };

      switch-layout = mkBindOption [
        mod
        "CTRL"
        "ALT"
        "SPACE"
      ];

      # ==== Actions ==== #
      center-window = mkBindOption [
        mod
        "C"
      ];
      toggle-overview = mkBindOption [
        mod
        "O"
      ];
      close-window = mkBindOption [
        mod
        "Q"
      ];
      toggle-fullscreen = mkBindOption [
        "F11"
      ];

      # ==== Scrolling ==== #
      move-workspace = {
        down = mkBindOption [
          mod
          "CTRL"
          "SHIFT"
          "J"
        ];
        up = mkBindOption [
          mod
          "CTRL"
          "SHIFT"
          "K"
        ];
      };

      switch-preset-column-width = mkBindOption [
        mod
        "W"
      ];
      switch-preset-window-height = mkBindOption [
        mod
        "S"
      ];
      expand-column-to-available-width = mkBindOption [
        mod
        "P"
      ];
      maximize-column = mkBindOption [
        mod
        "M"
      ];
      reset-window-height = mkBindOption [
        mod
        "CTRL"
        "S"
      ];

      # ==== Float ==== #
      toggle-float = mkBindOption [
        mod
        "V"
      ];
      switch-focus-between-floating-and-tiling = mkBindOption [
        mod
        "CTRL"
        "V"
      ];

      minimize = mkBindOption [
        mod
        "I"
      ];

      restore-minimize = mkBindOption [
        mod
        "SHIFT"
        "I"
      ];

      toggle-scratchpad = mkBindOption [
        mod
        "Z"
      ];

      # ==== Screenshot ==== #
      screenshot = {
        area = mkBindOption [
          mod
          "SHIFT"
          "S"
        ];
        window = mkBindOption [
          "CTRL"
          "SHIFT"
          "S"
        ];
        screen = mkBindOption [
          mod
          "CTRL"
          "SHIFT"
          "S"
        ];
      };

      toggle-control-center = mkBindOption [
        mod
        "SLASH"
      ];

      toggle-launcher = mkBindOption [
        "ALT"
        "SPACE"
      ];

      toggle-launcher-shortcuts = mkBindOption [
        mod
        "R"
      ];

      lock-screen = mkBindOption [
        mod
        "CTRL"
        "M"
      ];

      clipboard-history = mkBindOption [
        mod
        "COMMA"
      ];

      emoji = mkBindOption [
        mod
        "PERIOD"
      ];

      screen-recorder = mkBindOption [
        mod
        "F12"
      ];

      notification-center = mkBindOption [
        mod
        "N"
      ];

      toggle-dont-disturb = mkBindOption [
        mod
        "CTRL"
        "N"
      ];

      wallpaper-selector = mkBindOption [
        mod
        "CTRL"
        "W"
      ];

      wallpaper-random = mkBindOption [
        mod
        "CTRL"
        "SLASH"
      ];

      calculator = mkBindOption [
        mod
        "CTRL"
        "C"
      ];

      media = {
        prev = mkBindOption [
          mod
          "CTRL"
          "COMMA"
        ];

        next = mkBindOption [
          mod
          "CTRL"
          "PERIOD"
        ];
      };

      focus-workspace-prefix = mkBindOption [ mod ];
    };
  };
}
