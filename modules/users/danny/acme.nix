{
  flake.modules.nixos.danny =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf;
      inherit (config.sops) secrets;
    in
    {
      users.groups.acme.members = mkIf config.services.nginx.enable [ "nginx" ];

      sops.secrets = {
        "acme/cloudflare" = {
          mode = "0640";
        };
      };

      networking.firewall.allowedTCPPorts = [
        443
        80
      ];

      security.acme = {
        acceptTerms = true;
        certs."dnywe.com" = {
          domain = "*.dnywe.com";
          extraDomainNames = [
            "*.stalwart.dnywe.com"
            "dnywe.com"
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
    };
}
