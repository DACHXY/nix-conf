{
  hyprtasking = {
    layout = "grid";
    bg_color = "0xffebdbb2";

    gap_size = 20;

    gestures = {
      enabled = true;
      open_fingers = 3;
      open_distance = 300;
      open_positive = true;
    };

    linear = {
      height = 400;
      scroll_speed = 1.1;
      blur = 0;
    };
  };

  hyprwinrap = {
    class = "kitty-bg";
  };

  touch_gestures = {
    sensitivity = 4.0;
    workspace_swipe_fingers = 3;
    workspace_swipe_edge = "d";
    long_press_delay = 400;
    resize_on_border_long_press = true;
    edge_margin = 10;
    emulate_touchpad_swipe = false;
  };
}
