{
  domain ? "localhost",
  configureNginx ? true,
  passwordFile,
}:
{ config, lib, ... }:
let
  inherit (lib) mkIf optionalString;
in
{
  services.paperless = {
    enable = true;
    passwordFile = passwordFile;
    consumptionDirIsPublic = true;
    settings = {
      PAPERLESS_CONSUMER_IGNORE_PATTERN = [
        ".DS_STORE/*"
        "desktop.ini"
      ];
      PAPERLESS_OCR_LANGUAGE = "chi_tra+eng";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
      PAPERLESS_URL = "http${optionalString configureNginx "s"}://${domain}";
    };
    configureTika = false;
    database.createLocally = true;
  };

  services.nginx.virtualHosts."${domain}" = mkIf configureNginx {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://localhost:${toString config.services.paperless.port}";
  };
}
