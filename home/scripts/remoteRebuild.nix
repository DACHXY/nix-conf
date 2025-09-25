{ pkgs, ... }:
pkgs.writeShellScriptBin "rRebuild" ''
  TARGET=$1
  BUILD=$2

  shift
  shift

  nixos-rebuild switch --target-host "$TARGET" --build-host "$BUILD" --sudo --ask-sudo-password $@
''
