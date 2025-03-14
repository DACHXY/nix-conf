{
  input = {
    kb_layout = "us";

    kb_variant = "";
    kb_model = "";
    kb_rules = "";

    follow_mouse = 1;
    accel_profile = "flat";

    kb_options = "caps:swapescape";

    touchpad = {
      natural_scroll = true;
    };

    sensitivity = -0.1; # -1.0 - 1.0, 0 means no modification.
  };

  cursor = {
    no_hardware_cursors = true;
  };

  gestures = {
    workspace_swipe = true;
    workspace_swipe_fingers = 3;
  };
}
