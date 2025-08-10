{ config, pkgs }:
let
  mkWall = pkgs.writeShellScriptBin "setWall" ''
    url="$1"
    filepath="/tmp/wall_cache/$(echo -n "$url" | base64 | tr -d '\n')"

    if [[ ! -f "$filepath" ]]; then
        curl -sL "$url" -o "$filepath"
    fi

    ${config.services.swww.package}/bin/swww img "$filepath" \
      --transition-fps 45 \
      --transition-duration 1 \
      --transition-type random
  '';
in
mkWall
