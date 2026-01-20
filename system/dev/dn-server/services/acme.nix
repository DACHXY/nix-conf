{
  config,
  pkgs,
  ...
}:
let
  inherit (config.sops) secrets;
in
{
  users.users.nginx.extraGroups = [ "acme" ];

  sops.secrets = {
    "acme/pdns" = {
      mode = "0660";
      owner = "acme";
      group = "acme";
    };

    "acme/cloudflare" = {
      mode = "0640";
    };
  };

  systemConf.security.allowedDomains = [
    "acme-v02.api.letsencrypt.org"
    "api.cloudflare.com"
  ];

  security.acme = {
    acceptTerms = true;
    defaults = {
      server = "https://10.0.0.1:${toString config.services.step-ca.port}/acme/acme/directory";
      validMinDays = 2;
      renewInterval = "daily";
      email = "danny@net.dn";
      dnsProvider = "pdns";
      dnsPropagationCheck = false;
      environmentFile = secrets."acme/pdns".path;
    };

    certs."dnywe.com" = {
      domain = "*.dnywe.com";
      extraDomainNames = [
        "*.stalwart.dnywe.com"
      ];
      server = "https://acme-v02.api.letsencrypt.org/directory";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      email = "postmaster@dnywe.com";
      dnsPropagationCheck = true;
      environmentFile = pkgs.writeText "lego-config" ''
        LEGO_CA_CERTIFICATES=${config.security.pki.caBundle}
      '';
      credentialFiles = {
        "CLOUDFLARE_DNS_API_TOKEN_FILE" = secrets."acme/cloudflare".path;
      };
    };
  };
}
