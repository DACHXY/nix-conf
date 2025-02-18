{ monitors }:
let
  monitorNum = builtins.length monitors;
  workspaceNum = 10;
  workspaceList = builtins.genList (
    index:
    let
      currentNum = index - (monitorNum * (index / monitorNum));
    in
    "${builtins.toString (index + 1)}, monitor:${builtins.elemAt monitors currentNum}"
  ) workspaceNum;
in
if (monitorNum > 0) then workspaceList else [ ]
