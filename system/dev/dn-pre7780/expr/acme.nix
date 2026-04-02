{
  self,
  config,
  pkgs,
  ...
}:
let
  serverACMEConfig = self.nixosConfigurations.dn-server.config.security.acme.certs."dnywe.com";
  inherit (config.sops) secrets;
in
{
  users.users.nginx.extraGroups = [ "acme" ];

  sops.secrets = {
    "acme/cloudflare" = {
      mode = "0640";
    };
  };

  security.acme = {
    acceptTerms = true;
    certs."dnywe.com" = {
      inherit (serverACMEConfig)
        domain
        server
        dnsProvider
        email
        dnsResolver
        dnsPropagationCheck
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
  };
}
