{ ... }:
let
  icons = {
    lock = ../config/wlogout/icons/lock.svg;
    hibernate = ../config/wlogout/icons/hibernate.svg;
    logout = ../config/wlogout/icons/logout.svg;
    shutdown = ../config/wlogout/icons/shutdown.svg;
    suspend = ../config/wlogout/icons/suspend.svg;
    reboot = ../config/wlogout/icons/reboot.svg;
  };
in
{
  programs.wlogout = {
    enable = true;
    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "logout";
        action = "sleep 1; hyprctl dispatch exit";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
    ];
    style =
      # css
      ''
        @define-color main #ebdbb2;

        * {
          background-image: none;
          transition-property: all;
          transition-duration: 0.3s;
        }

        window {
          background-color: rgba(0, 0, 0, 0);
        }

        button {
          margin: 8px;
          color: @main;
          border-style: solid;
          border-width: 2px;
          background-position: center center;
          background-size: 15%;
          background-repeat: no-repeat;
        }

        button:active,
        button:focus,
        button:hover {
          color: @main;
          background-color: alpha(@main, 0.4);
          outline-style: none;
          transition-property: all;
          transition-duration: 0.3s;
        }

        #lock {
          background-image: url("${icons.lock}");
        }

        #logout {
          background-image: url("${icons.logout}");
        }

        #suspend {
          background-image: url("${icons.suspend}");
        }

        #hibernate {
          background-image: url("${icons.hibernate}");
        }

        #shutdown {
          background-image: url("${icons.shutdown}");
        }

        #reboot {
          background-image: url("${icons.reboot}");
        }
      '';
  };
}
