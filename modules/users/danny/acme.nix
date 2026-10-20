{
  flake.modules.nixos.danny-acme =
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
          # lego 5's propagation checks cannot be used from this network:
          #   * recursive check -> public resolvers negative-cache the
          #     NXDOMAIN of `_acme-challenge.dnywe.com` (it only exists during a
          #     ~2 minute order window), for the zone's SOA minimum of 1800s.
          #   * authoritative check -> the campus line drops outbound UDP/53 to
          #     part of Cloudflare's anycast range: "read udp
          #     140.113.168.237:49423->173.245.58.78:53: i/o timeout".
          # Both are local-network problems, not DNS-record problems: during a
          # run the TXT record is verifiably live on brit/jim.ns.cloudflare.com
          # within a second. So skip the checks and wait long enough for
          # Let's Encrypt (which resolves from its own network) to see it.
          dnsPropagationCheck = false;
          extraLegoFlags = [
            "--dns.propagation.wait"
            "60s"
          ];
          extraDomainNames = [
            "dnywe.com"
          ];
          server = "https://acme-v02.api.letsencrypt.org/directory";
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          email = "postmaster@dnywe.com";
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
