# Pi skills kept in this repo and linked into ~/.pi/agent/skills on every device.
#
# Drop a new skill in as modules/skills/<name>/SKILL.md and it is picked up on the
# next rebuild — no registration needed.
{ ... }:
{
  flake.modules.homeManager.ai =
    { lib, ... }:
    let
      skillsDir = ./skills;
      skillNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
      );
    in
    {
      home.file = lib.listToAttrs (
        map (name: lib.nameValuePair ".pi/agent/skills/${name}" { source = skillsDir + "/${name}"; }) skillNames
      );
    };
}
