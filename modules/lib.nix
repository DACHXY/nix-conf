{ inputs, ... }:
{
  flake.lib =
    let
      inherit (inputs.nixpkgs) lib;
      inherit (builtins) toJSON;
      inherit (lib)
        optionalString
        toUpper
        substring
        concatStringsSep
        splitString
        ;
    in
    {
      capitalize = text: "${toUpper (substring 0 1 text)}${substring 1 (-1) text}";

      grafana = {
        mkDashboard =
          {
            pkgs,
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

      nftables = {
        mkElementsStatement =
          elements:
          optionalString (builtins.length elements > 0) "elements = { ${concatStringsSep "," elements} }";
      };

      ldap = {
        getOlcSuffix = domain: concatStringsSep "," (map (dc: "dc=${dc}") (splitString "." domain));
      };
    };
}
