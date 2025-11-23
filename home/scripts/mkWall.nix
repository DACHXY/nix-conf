{ config, pkgs }:
let
  mkWall = pkgs.writeShellScriptBin "setWall" ''
    url="$1"
    DIR="$HOME/Pictures/Wallpapers"
    filepath="$DIR/$(echo -n "$url" | sha256sum | awk '{print $1}' | tr -d '\n').jpg"

    if [[ ! -f "$filepath" ]]; then
        ${pkgs.libnotify}/bin/notify-send " Wallpaper" "$filepath\nDownloading..."
        curl -sL "$url" -o "$filepath"
    fi

    ${config.services.swww.package}/bin/awww img "$filepath" \
      --transition-fps 45 \
      --transition-duration 1 \
      --transition-type random
  '';
in
mkWall
