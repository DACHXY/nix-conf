final: prev:
let
  discordIcon = prev.lib.readFile ../../pkgs/assets/discord.svg;
  discordSplash = prev.lib.readFile ../../pkgs/assets/peepoLeave.gif.base64;

  hideChannels = prev.pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Farcrada/DiscordPlugins/cf906b358eddfe75edba215e33020c234be514b7/Hide-Channels/HideChannels.plugin.js";
    hash = "sha256-JdwKnGHMtJU1hKRlx1TXSHWUA2hT5D6vw1Ez46Hhe5c=";
  };
in
{
  vesktop = prev.vesktop.overrideAttrs (oldAttrs: {
    desktopItems = prev.lib.optional prev.stdenv.hostPlatform.isLinux (
      (prev.lib.head oldAttrs.desktopItems).override {
        name = "discord";
        desktopName = "Discord";
      }
    );

    postPatch = ''
      # Add plugins
      mkdir -p src/userplugins
      cp ${hideChannels} src/userplugins/hideChannels.js
    '';

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
