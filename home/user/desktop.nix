{
  nvidia-offload-enabled,
  lib,
  pkgs,
  ...
}:
let
  offloadScript = import ../../system/modules/offload.nix { inherit pkgs; };
  launcher = "${offloadScript}/bin/offload firefox";
in
with lib;
{
  xdg.desktopEntries = lib.mkIf nvidia-offload-enabled {
    firefox = {
      actions = {
        "new-private-window" = {
          exec = "${launcher} --private-window %U";
          name = "New Private Window";
        };
        "new-window" = {
          exec = "${launcher} --new-window %U";
          name = "New Window";
        };
        "profile-manager-window" = {
          exec = "${launcher} --ProfileManager";
          name = "Profile Manager";
        };
      };
      exec = "${launcher} --name firefox %U";
      categories = [
        "Network"
        "WebBrowser"
      ];
      genericName = "Web Browser";
      name = "Firefox";
      startupNotify = true;
      terminal = false;
      type = "Application";
      icon = "firefox";
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };
  };
}
