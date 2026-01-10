{
  pkgs,
  config,
  ...
}:
let
  # ==== Needed for special import ==== #
  shadps4-7 = pkgs.shadps4.overrideAttrs (_: rec {
    version = "0.7.0";
    src = pkgs.fetchFromGitHub {
      owner = "shadps4-emu";
      repo = "shadPS4";
      rev = "v.${version}";
      hash = "sha256-g55Ob74Yhnnrsv9+fNA1+uTJ0H2nyH5UT4ITHnrGKDo=";
      fetchSubmodules = true;
    };
  });
in
{
  environment.systemPackages = with pkgs; [
    shadps4
  ];

  home-manager = {
    users."${config.systemConf.username}" = {
      home.file = {
        # CS go
        ".steam/steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg/autoexec.cfg".text = ''
          fps_max "250"

          # Wheel Jump
          bind "mwheeldown" "+jump"
          bind "mwheelup" "+jump"
          bind "space" "+jump"

          echo "AUTOEXEC LOADED SUCCESSFULLY!"
          host_writeconfig
        '';
      };
    };
  };
}
