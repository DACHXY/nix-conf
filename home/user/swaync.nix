{ pkgs, ... }:
{
  services.swaync = {
    enable = true;

    settings = {
      "positionX" = "right";
      "positionY" = "top";
      "layer" = "overlay";
      "control-center-margin-top" = 20;
      "control-center-margin-bottom" = 20;
      "control-center-margin-right" = 20;
      "control-center-margin-left" = 20;
      "notification-icon-size" = 64;
      "notification-body-image-height" = 100;
      "notification-body-image-width" = 200;
      "timeout" = 3;
      "timeout-low" = 2;
      "timeout-critical" = 0;
      "fit-to-screen" = false;
      "control-center-width" = 500;
      "control-center-height" = 900;
      "notification-window-width" = 490;
      "keyboard-shortcuts" = true;
      "image-visibility" = "when-available";
      "transition-time" = 200;
      "hide-on-clear" = true;
      "hide-on-action" = true;
      "script-fail-notify" = true;
      "widgets" = [
        "title"
        "notifications"
        "mpris"
      ];
    };

    style = ''
      @define-color bgc rgba(0, 0, 0, 0.1);
      @define-color borderc #ebdbb2;
      @define-color textc #282828;

      .SwayNotificationCenterNotificationWindow {
        background: @bgc;
        background-color: @bgc;
      }

      .control-center .notification-row:focus,
      .control-center .notification-row:hover {
        opacity: 1;
        background: @bgc;
      }

      .notification-row {
        outline: none;
        margin: 20px;
        padding: 0;
      }

      .notification {
        background: @textc;
        margin: 0px;
        border-radius: 0px;
        border-width: 3px;
        border-color: #ebdbb2;
      }

      .notification-content {
        background: @textc;
        padding: 7px;
        margin: 0;
      }

      .close-button {
        background: @textc;
        color: @borderc;
        text-shadow: none;
        padding: 0;
        border-radius: 20px;
        margin-top: 9px;
        margin-right: 5px;
      }

      .close-button:hover {
        box-shadow: none;
        background: @borderc;
        color: @textc;
        transition: all 0.15s ease-in-out;
        border: none;
      }

      .notification-action {
        color: @bgc;
        background: @textc;
      }

      .summary {
        padding-top: 7px;
        font-size: 13px;
        color: @borderc;
      }

      .time {
        font-size: 11px;
        color: @borderc;
        margin-right: 40px;
      }

      .body {
        font-size: 12px;
        color: @borderc;
      }

      .control-center {
        background-color: @bgc;
        border-radius: 20px;
      }

      .control-center-list {
        background: transparent;
      }

      .control-center-list-placeholder {
        opacity: 0.5;
      }

      .floating-notifications {
        background: transparent;
      }

      .blank-window {
        background: alpha(black, 0.1);
      }

      .widget-title {
        color: @borderc;
        padding: 10px 10px;
        margin: 10px 10px 5px 10px;
        font-size: 1.5rem;
      }

      .widget-title > button {
        font-size: 1rem;
        color: @borderc;
        padding: 10px;
        text-shadow: none;
        background: @bgc;
        box-shadow: none;
        border-radius: 5px;
      }

      .widget-title > button:hover {
        background: @borderc;
        color: #282828;
      }

      .widget-label {
        margin: 10px 10px 10px 10px;
      }

      .widget-label > label {
        font-size: 1rem;
        color: @textc;
      }

      .widget-mpris {
        color: @borderc;
        padding: 5px 5px 5px 5px;
        margin: 10px;
        border-radius: 20px;
      }

      .widget-mpris > box > button {
        border-radius: 20px;
      }

      .widget-mpris-player {
        padding: 5px 5px;
        margin: 10px;
      }
    '';
  };
}
