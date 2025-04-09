{ config }:
final: prev:
let
  discordIcon = prev.lib.readFile ../../pkgs/assets/discord.svg;
  discordSplash = prev.lib.readFile ../../pkgs/assets/peepoLeave.gif.base64;
in
{
  vesktop = prev.vesktop.overrideAttrs (oldAttrs: {
    desktopItems = prev.lib.optional prev.stdenv.hostPlatform.isLinux (
      (prev.lib.head oldAttrs.desktopItems).override {
        name = "discord";
        desktopName = "Discord";
        exec =
          if config.hardware.nvidia.prime.offload.enableOffloadCmd == true then
            "nvidia-offload vesktop %U"
          else
            "vesktop %U";
      }
    );

    patches = oldAttrs.patches ++ [
      ../../pkgs/patches/splash.patch
    ];

    # Change Splash
    preConfigure = ''
      echo "${discordSplash}" | base64 -d > static/peepo.gif
    '';

    # Change Icon
    postInstall = ''
      rm -rf $out/share/icons/hicolor/*
      mkdir -p $out/share/icons/hicolor/scalable/apps
      echo '${discordIcon}' > $out/share/icons/hicolor/scalable/apps/vesktop.svg
    '';
  });
}
