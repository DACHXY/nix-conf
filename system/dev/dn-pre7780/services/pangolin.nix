{ config, lib, ... }:
let
  inherit (lib) mkForce;
  secrets = config.sops.secrets;
  domain = "net.dn";
in
{
  sops.secrets = {
    "pangolin/env" = { };
    "pangolin/traefik" = {
      key = "acme/pdns";
    };
  };

  services.pangolin = {
    enable = true;
    openFirewall = true;
    dashboardDomain = "auth.${domain}";
    baseDomain = domain;

    environmentFile = secrets."pangolin/env".path;
    letsEncryptEmail = "danny@net.dn";
    dnsProvider = "pdns";

    settings = {
      app = {
        save_logs = true;
      };
      domains = {

      };
      traefik.prefer_wildcard_cert = true;
    };
  };

  services.traefik = {
    staticConfigOptions = {
      certificatesResolvers.letsencrypt.acme = {
        caServer = mkForce "https://ca.net.dn/acme/acme/directory";
        dnsChallenge = {
          provider = "pdns";
          resolvers = [ "10.0.0.1:53" ];
        };
      };
    };
    environmentFiles = [ secrets."pangolin/traefik".path ];
  };
}
