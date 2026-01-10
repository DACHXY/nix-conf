{
  osConfig,
  config,
  pkgs,
}:
let
  inherit (osConfig.networking) hostName;
  shouldNotify =
    (builtins.hasAttr "ntfy-client" config.services) && config.services.ntfy-client.enable;
  rebuildCommand = ''
    nixos-rebuild switch --target-host "$TARGET" \
      --build-host "$BUILD" \
      --sudo --ask-sudo-password $@'';
in
pkgs.writeShellScriptBin "rRebuild" ''
  NOTIFY="''\${NOTIFY:-0}"
  TARGET=$1
  BUILD=$2

  set -euo pipefail

  shift 2

  ${
    if shouldNotify then
      ''
        export NTFY_TITLE="🎯 $TARGET built by 🏗️ ''\${BUILD:-${hostName}}" 
        export NTFY_TAGS="gear"

        if [ "$NOTIFY" -eq 0 ] ; then
          ${rebuildCommand}
          exit 0
        fi

        if ${rebuildCommand}
        then
          ntfy pub system-build "✅ Build success" > /dev/null 2>&1
        else
          ntfy pub system-build "⛔ Build failed" > /dev/null 2>&1
        fi
      ''
    else
      rebuildCommand
  }
''
