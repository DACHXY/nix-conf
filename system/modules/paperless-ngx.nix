{
  domain ? "localhost",
  passwordFile,
}:
{ config, ... }:
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
      PAPERLESS_URL = "https://${domain}";
    };
    configureTika = true;
    database.createLocally = true;
  };

  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://localhost:${toString config.services.paperless.port}";
  };
}
