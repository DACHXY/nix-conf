{ pkgs, config }:
let
  mkWall = import ./mkWall.nix { inherit pkgs config; };
  rofiWall = pkgs.writeShellScript "rofiWall" ''
    url=$(rofi -i -dmenu -config ~/.config/rofi/config.rasi -p "URL")
    ${mkWall}/bin/setWall "$url"
  '';
in
rofiWall
