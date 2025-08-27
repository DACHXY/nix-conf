{
  pkgs,
  lib,
}:
let
  inherit (pkgs) writeShellScript;
  inherit (lib) replaceString;
  inherit (builtins) toJSON mapAttrs;
in
{
  mkToggleScript =
    {
      service,
      start,
      stop,
      icon ? "",
      extra ? { },
    }:
    let
      extraJson = replaceString "\"" "\\\"" (toJSON extra);
    in
    writeShellScript "${service}-toggle.sh" ''
      SERVICE_NAME=${service}
      EXTRA_JSON="${extraJson}"

      case $1 in toggle)
        if systemctl --user is-active --quiet "$SERVICE_NAME"; then
            systemctl --user stop "$SERVICE_NAME"
            notify-send "${icon} ''\${SERVICE_NAME^}" "stopping"
        else
            systemctl --user start "$SERVICE_NAME"
            notify-send "${icon} ''\${SERVICE_NAME^}" "starting"
        fi
      esac

      if systemctl --user is-active --quiet "$SERVICE_NAME"; then
        json1=$(jq -nc --arg text "${icon} ''\${SERVICE_NAME^} starting" --arg class "${start}" \
        '{text: $text, tooltip: $text, class: $class, alt: $class}')
      else
        json1=$(jq -nc --arg text "${icon} ''\${SERVICE_NAME^} stopped" --arg class "${stop}" \
        '{text: $text, tooltip: $text, class: $class, alt: $class}')
      fi

      jq -nc --argjson a "$json1" --argjson b "$EXTRA_JSON" '$a + $b'
    '';
}
