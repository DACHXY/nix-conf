{
  pkgs,
  pkgs-stable,
  config,
  inputs,
  ...
}:
let
  protonGEVersion = "10-15";
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
  environment.systemPackages = [
    pkgs-stable.shadps4
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

        # Proton GE
        ".steam/root/compatibilitytools.d/GE-Proton${protonGEVersion}" = {
          source = fetchTarball {
            url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton${protonGEVersion}/GE-Proton${protonGEVersion}.tar.gz";
            sha256 = "sha256:0iv7vak4a42b5m772gqr6wnarswib6dmybfcdjn3snvwxcb6hbsm";
          };
        };
        ".steam/root/compatibilitytools.d/CachyOS-Proton10-0_v3" = {
          source = fetchTarball {
            url = "https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-10.0-20250714-slr/proton-cachyos-10.0-20250714-slr-x86_64_v3.tar.xz";
            sha256 = "sha256:0hp22hkfv3f1p75im3xpif0pmixkq2i3hq3dhllzr2r7l1qx16iz";
          };
        };
      };
    };
  };
}
