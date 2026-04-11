{
  self,
  config,
  pkgs,
  ...
}:
let
  serverCfg = self.nixosConfigurations.dn-server.config;
  inherit (serverCfg.networking) domain;
  serverACMEConfig = serverCfg.security.acme.certs."${domain}";
  inherit (config.sops) secrets;

  acmeSettings = {
    inherit (serverACMEConfig)
      domain
      server
      dnsProvider
      email
      extraDomains
      ;

    extraLegoFlags = [
      "--dns.propagation-wait"
      "5s"
    ];
    environmentFile = pkgs.writeText "lego-config" ''
      LEGO_CA_CERTIFICATES=${config.security.pki.caBundle}
    '';
    credentialFiles = {
      "CLOUDFLARE_DNS_API_TOKEN_FILE" = secrets."acme/cloudflare".path;
    };
  };
in
{
  sops.secrets = {
    "acme/cloudflare" = {
      mode = "640";
      owner = "acme";
      group = "acme";
    };
  };

  security.acme = {
    acceptTerms = true;
    certs."${domain}" = acmeSettings;
    certs."coturn.${domain}" = acmeSettings;
  };
}
