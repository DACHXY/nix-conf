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
    splitString
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

  getMonitors =
    profileName: config:
    let
      inherit (lib)
        pipe
        filter
        elemAt
        length
        ;
    in
    (pipe config.services.kanshi.settings [
      (x: filter (p: p.profile.name == profileName) x)
      (x: if (length x > 0) then elemAt x 0 else { profile.outputs = [ ]; })
      (x: x.profile.outputs)
    ]);

  ldap = {
    getOlcSuffix = domain: concatStringsSep "," (map (dc: "dc=${dc}") (splitString "." domain));
  };

  sendMail =
    {
      username,
      password,
      server ? "https://stalwart.dnywe.com",
      from,
      to,
      subject ? "test",
      content ? "test",
    }:
    pkgs.writeShellScriptBin "sendMail" ''
      PATH="$PATH:${pkgs.jq}/bin:${pkgs.curl}/bin"
      API_BASE=${server}
      API_URL=${server}/jmap
      USERNAME=${username}
      PASSWORD=${password}

      set -euo pipefail

      session_data=$(curl -s -L -u "$USERNAME:$PASSWORD" \
        -H "Content-Type: application/json" \
        $API_BASE/.well-known/jmap)

      ACCOUNT_ID=$(echo "$session_data" | jq -r '.primaryAccounts["urn:ietf:params:jmap:mail"] // empty')

      if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" == "null" ]; then
        echo "ERROR: Cannot get Account ID. Check your credentials."
        echo "Response: $session_data"
        exit 1
      fi

      echo "Account Id Get."

      echo "Getting mailbox."

      INFO_RESP=$(curl -s -u "$USERNAME:$PASSWORD" -X POST "$API_URL" -H "Content-Type: application/json" -d "{
        \"using\": [\"urn:ietf:params:jmap:mail\", \"urn:ietf:params:jmap:submission\"],
        \"methodCalls\": [
          [\"Mailbox/get\", {\"accountId\": \"$ACCOUNT_ID\"}, \"a\"],
          [\"Identity/get\", {\"accountId\": \"$ACCOUNT_ID\"}, \"b\"]
        ]
      }")

      MAILBOX_ID=$(echo "$INFO_RESP" | jq -r '.methodResponses[0][1].list[] | select(.role == "drafts") | .id')
      IDENTITY_ID=$(echo "$INFO_RESP" | jq -r '.methodResponses[1][1].list[0].id')

      if [ -z "$IDENTITY_ID" ] || [ "$IDENTITY_ID" == "null" ]; then
          echo "Identity ID not found."
          exit 1
      fi

      echo "Identity ID found: $IDENTITY_ID"

      if [ -z "$MAILBOX_ID" ]; then
          echo "Mailbox draft Id not found, fallback to Inbox (ID: a)"
          MAILBOX_ID="a"
      else
          echo "Draft Id found: $MAILBOX_ID"
      fi

      JSON_DATA=$(jq -n --arg accId "$ACCOUNT_ID" --arg mailboxId "$MAILBOX_ID" --arg identityId "$IDENTITY_ID" '{
        "methodCalls": [
          [
            "Email/set",
            {
              "accountId": $accId,
              "create": {
                "m1": {
                  "mailboxIds": { ($mailboxId): true },
                  "bodyValues": {
                    "b1": {
                      "isTruncated": false,
                      "value": "${content}"
                    }
                  },
                  "from": [
                    {
                      "email": "${from}"
                    }
                  ],
                  "subject": "${subject}",
                  "textBody": [
                    {
                      "partId": "b1",
                      "type": "text/plain"
                    }
                  ],
                  "to": [
                    {
                      "email": "${to}"
                    }
                  ]
                }
              }
            },
            "a"
          ],
          [
            "EmailSubmission/set",
            {
              "accountId": $accId,
              "create": {
                "s1": {
                  "emailId": "#m1",
                  "identityId": $identityId
                }
              },
              "onSuccessDestroyEmail": [
                "#m1"
              ]
            },
            "b"
          ]
        ],
        "using": [
          "urn:ietf:params:jmap:core",
          "urn:ietf:params:jmap:mail",
          "urn:ietf:params:jmap:submission"
        ]
      }
      ')

      SEND_RESP=$(curl -s -u "$USERNAME:$PASSWORD" -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "$JSON_DATA")

      SUBMISSION_ID=$(echo "$SEND_RESP" | jq -r '.methodResponses[1][1].created.s1.id // empty')

      if [ -n "$SUBMISSION_ID" ]; then
          echo "Sent."
      else
          echo "Failed to sent"
          echo "$SEND_RESP" | jq .
      fi
    '';
}
