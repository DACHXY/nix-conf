{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = "us";

      kb_variant = "";
      kb_model = "";
      kb_rules = "";

      repeat_delay = 250;
      repeat_rate = 35;

      follow_mouse = 1;
      accel_profile = "flat";

      kb_options = [ "caps:escape" ];

      touchpad = {
        natural_scroll = true;
      };

      sensitivity = -0.1; # -1.0 - 1.0, 0 means no modification.
    };
    binds = {
      scroll_event_delay = 0;
    };

    cursor = {
      no_hardware_cursors = true;
    };

    gesture = [
      "3, horizontal, workspace"
    ];
  };
}
