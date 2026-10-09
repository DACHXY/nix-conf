# Agent skills kept in this repo and linked into ~/.pi/agent/skills and
# ~/.claude/skills on every device.
#
# Drop a new skill in as modules/skills/<name>/SKILL.md and it is picked up on the
# next rebuild — no registration needed. A skill that ships inside another
# package is linked from that package instead (see the herdr entry below).
{ ... }:
{
  flake.modules.homeManager.ai =
    { lib, pkgs, ... }:
    let
      skillsDir = ./skills;
      skillNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
      );

      # name -> skill directory. Local skills come from modules/skills/.
      skills =
        lib.listToAttrs (map (name: lib.nameValuePair name (skillsDir + "/${name}")) skillNames)
        // {
          # This skill ships inside the herdr package, so link it from there to
          # stay in lockstep with the installed herdr instead of copying it here.
          herdr = "${pkgs.herdr}/share/skills/herdr/herdr";
        };

      linkTo =
        root: lib.mapAttrs' (name: source: lib.nameValuePair "${root}/${name}" { inherit source; }) skills;
    in
    {
      home.file = linkTo ".pi/agent/skills" // linkTo ".claude/skills";
    };
}
