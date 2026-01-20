{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) getExe;
  inherit (config.sops) secrets;
in
{
  sops.secrets = {
    "openfortivpn" = { };
  };

  systemd.services.openfortivpn = {
    script = ''
      ${getExe pkgs.openfortivpn} -c "$CREDENTIALS_DIRECTORY/config" --set-dns=1 --use-resolvconf=1
    '';
    serviceConfig = {
      Restart = "no";
      LoadCredential = [
        "config:${secrets."openfortivpn".path}"
      ];
    };
  };
}
