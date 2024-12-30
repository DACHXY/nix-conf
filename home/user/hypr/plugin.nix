{
  hyprexpo = {
    columns = 3;
    gap_size = 5;
    bg_col = "rgb(111111)";
    workspace_method = "center current"; # [center/first] [workspace] e.g. first 1 or center m+1
    enable_gesture = true; # laptop touchpad
    gesture_fingers = 3; # 3 or 4
    gesture_distance = 300; # how far is the "max"
    gesture_positive = true; # positive = swipe down. Negative = swipe up.
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
