{
  pkgs,
  lib,
}:
let
  inherit (pkgs) writeShellScript;
  inherit (lib)
    replaceString
    optionalString
    toUpper
    substring
    concatStringsSep
    ;
  inherit (builtins) toJSON;
in
{
  mkToggleScript =
    {
      service,
      start,
      stop,
      icon ? "",
      notify-icon ? "",
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
            notify-send ${
              optionalString (notify-icon != "") "-i ${notify-icon}"
            } "${icon} ''\${SERVICE_NAME^}" "stopping"
        else
            systemctl --user start "$SERVICE_NAME"
            notify-send ${
              optionalString (notify-icon != "") "-i ${notify-icon}"
            } "${icon} ''\${SERVICE_NAME^}" "starting"
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

  grafana = {
    mkDashboard =
      {
        name,
        src,
        templateList,
        conf ? { },
      }:
      let
        template = toJSON templateList;
      in
      pkgs.stdenvNoCC.mkDerivation (
        {
          inherit src;
          pname = "${name}-grafana-dashboard-srouce";
          version = "1.0";
          dontBuild = true;
          nativeBuildInputs = with pkgs; [ jq ];

          installPhase = ''
            PROM_TEMPLATE='${template}'
            OUTPUT_PATH="$out"

            mkdir -p $out

            if [ -f "$src" ]; then
              echo "adding template filename: $(basename $src)"
              jq --argjson TEMPLATE "$PROM_TEMPLATE" '.templating.list += $TEMPLATE' \
              "$src" > "$OUTPUT_PATH/$(basename $src)"
            else
              find . -name "*.json" | while read DASHBOARD_FILE; do
                echo "adding template filename: $DASHBOARD_FILE"
                jq --argjson TEMPLATE "$PROM_TEMPLATE" '
                  .templating.list += $TEMPLATE
                ' "$DASHBOARD_FILE" > "$OUTPUT_PATH/$DASHBOARD_FILE"
              done
            fi
          '';
        }
        // conf
      );
  };

  capitalize = text: "${toUpper (substring 0 1 text)}${substring 1 (-1) text}";

  nftables = {
    mkElementsStatement =
      elements:
      optionalString (builtins.length elements > 0) "elements = { ${concatStringsSep "," elements} }";
  };
}
