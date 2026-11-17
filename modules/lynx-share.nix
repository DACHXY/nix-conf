# LYNX-SHARE: open-source DAW (C++/JUCE, https://github.com/Ka1-S/LYNX-SHARE)
# shortcut: pinned to v0.1.29-alpha AppImage (not in nixpkgs); bump tag+hash on upgrade
{ config, ... }:
{
  flake.modules.nixos.lynx-share =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (config.my.user) name;

      lynxAppImage = pkgs.fetchurl {
        url = "https://github.com/Ka1-S/LYNX-SHARE/releases/download/v0.1.29-alpha/LYNX-0.1.29-alpha-x86_64.AppImage";
        hash = "sha256-65367bfa8228bcfd0cc5fb6878dbc79a94b6038ceb78fe7fb2e5f396314d6519";
      };

      lynxLogo = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/Ka1-S/LYNX-SHARE/v0.1.29-alpha/docs/img/logo.png";
        hash = "sha256-1vxm17vhBztKR/bXMDtFPNluPUJ8ko1S1q8/rw6lKm4=";
      };

      # appimage-run provides the FHS env; AppImage needs glibc-2.35 userland
      lynx-share = pkgs.writeShellApplication {
        name = "lynx-share";
        runtimeInputs = [ pkgs.appimage-run ];
        text = ''exec appimage-run ${lynxAppImage} "$@"'';
      };
    in
    {
      home-manager.users.${name} = {
        home.packages = [ lynx-share ];

        xdg.desktopEntries.lynx-share = {
          name = "LYNX SHARE";
          comment = "Open-source DAW (FL Studio / Ableton style workflows)";
          exec = "lynx-share %U";
          icon = "${lynxLogo}";
          categories = [
            "AudioVideo"
            "Audio"
            "Sequencer"
          ];
          terminal = false;
        };
      };
    };
}
