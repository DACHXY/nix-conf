{
  config,
  pkgs,
  lib,
}:
let
  inherit (lib) getExe';
in
pkgs.writeShellScriptBin "ntfy" ''
  set -o allexport
  source "${config.sops.secrets."ntfy".path}"
  set +o allexport

  ${getExe' pkgs.ntfy-sh "ntfy"} "$@"
''
