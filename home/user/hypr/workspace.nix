{ monitors }:
let
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
    "${toString (index + 1)}, monitor:${elemAt monitors currentNum}, default:${default}"
  ) workspaceNum;
in
if (monitorNum > 0) then workspaceList else [ ]
