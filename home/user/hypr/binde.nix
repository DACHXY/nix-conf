{ mainMod }:
let
  resizeStep = builtins.toString 20;
  brightnessStep = builtins.toString 10;
  volumeStep = builtins.toString 2;
in
[
  '',XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_SINK@ 0 && wpctl set-volume @DEFAULT_SINK@ ${volumeStep}%+''
  '',XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_SINK@ 0 && wpctl set-volume @DEFAULT_SINK@ ${volumeStep}%-''
  '',XF86MonBrightnessDown, exec, brightnessctl set ${brightnessStep}%-''
  '',XF86MonBrightnessUp, exec, brightnessctl set ${brightnessStep}%+''
  ''${mainMod} CTRL, l, resizeactive, ${resizeStep} 0''
  ''${mainMod} CTRL, h, resizeactive, -${resizeStep} 0''
  ''${mainMod} CTRL, k, resizeactive, 0 -${resizeStep}''
  ''${mainMod} CTRL, j, resizeactive, 0 ${resizeStep}''
]
