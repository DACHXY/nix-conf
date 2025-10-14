{ osConfig, ... }:
let
  inherit (osConfig.systemConf.hyprland) monitors;
  inherit (builtins)
    length
    genList
    toString
    elemAt
    ;
  monitorNum = length monitors;
  workspaceNum = 10;
  workspaceList = genList (
    index:
    let
      currentNum = index - (monitorNum * (index / monitorNum));
      default = if index < monitorNum then "true" else "false";
    in
    "${toString (index + 1)}, monitor:desc:${(elemAt monitors currentNum).desc}, default:${default}"
  ) workspaceNum;
in
{
  wayland.windowManager.hyprland.settings.workspace = if (monitorNum > 0) then workspaceList else [ ];
}
