{ monitors }:
let
  monitorNum = builtins.length monitors;
  workspaceNum = 10;
  workspaceList = builtins.genList (
    index:
    let
      currentNum = index - (monitorNum * (index / monitorNum));
      default = if index < monitorNum then "true" else "false";
    in
    "${builtins.toString (index + 1)}, monitor:${builtins.elemAt monitors currentNum}, default:${default}"
  ) workspaceNum;
in
if (monitorNum > 0) then workspaceList else [ ]
