# Rofi selecter for bitwarden cli
{
  pkgs,
}:
let
  selector = pkgs.writeShellScript "rbw-selector" ''
    selection=$(rbw list | rofi -dmenu -p "Search" )

    if [[ -z "$selection" ]]; then
      exit 0
    fi

    rbw get "$selection" | tr -d '\n' | wl-copy
    notify-send "󰯄 Bitwarden" "Password for $selection: Copied"
  '';
in
selector
