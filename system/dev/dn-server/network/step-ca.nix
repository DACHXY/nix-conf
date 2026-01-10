{ pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [ step-cli ];

  users.users.step-ca = {
    isSystemUser = true;
    group = "step-ca";
  };

  users.groups.step-ca = { };

  networking.firewall.allowedTCPPorts = [ 8443 ];

  services.step-ca = {
    enable = true;
    address = "0.0.0.0";
    settings = {
      address = ":443";
      authority = {
        provisioners = [
          {
            encryptedKey = "eyJhbGciOiJQQkVTMi1IUzI1NitBMTI4S1ciLCJjdHkiOiJqd2sranNvbiIsImVuYyI6IkEyNTZHQ00iLCJwMmMiOjYwMDAwMCwicDJzIjoiUTZYbDJOdkFabGZZSTZ5QnBrZWp6dyJ9.z
Bq-3sY8n13Dv0E6yx2hVIAlzLj3aE29LC4A2j81vW5MtpaM27lMpg.cwlqZ-8l1iZNeeS9.idRpRJ9zB1ezz4NvpSDe9GIweBlTLH4DpZ7As65QftJf-32vFeSjw_8So8ugpS2BmfWaMcL6rHxJG369zf-Ninecy3yg4AvQ0WvzUWCYnR2m5-B2YYFJ0SlTv-FXOf_412ZaGdIK9FQo
8LszKMGzw0e3YkBuAAfEsqYaCTd27trDDPUelTVnC20zblVDEkBlusvoNeYEiy7nphjqy2OPW6bxLKdQMg-b9zVgZqkImRqojBBqnV85sBHaSyQWA9rP2PPJM8AVjVBtrVLG3YIVObbjiLAa21WMaFe1bW4LK7BNj7KwQ2JJzlBfkDkdmo3gZvYag--9AarieKeIumQ.Vxj5NwzSurT
47yHhoiCOug";
            key = {
              alg = "ES256";
              crv = "P-256";
              kid = "ywqnDBi0j1wjIx4i8xOBhqd6sCqsI_Z7aGQ6QifKFtM";
              kty = "EC";
              use = "sig";
              x = "o-Srd0v3IY7zU9U2COE9BOsjyIPjBvNT2WKPTo8ePZI";
              y = "y5OFjciRMVg8ePaEsjSPWbKp_NjQ6U4CtbplRx7z3Bw";
            };
            name = "danny@net.dn";
            type = "JWK";
          }
          {
            claims = {
              minTLSCertDuration = "32h";
              maxTLSCertDuration = "72h";
              defaultTLSCertDuration = "72h";
            };
            name = "acme";
            options = {
              enableRenewal = true;
            };
            type = "ACME";
          }
        ];
      };
      crt = "/var/lib/step-ca/certs/intermediate_ca.crt";
      db = {
        badgerFileLoadingMode = "";
        dataSource = "/var/lib/step-ca/db";
        type = "badgerv2";
      };
      dnsNames = [
        "10.0.0.1"
        "ca.net.dn"
      ];
      federatedRoots = null;
      insecureAddress = "";
      key = "/var/lib/step-ca/secrets/intermediate_ca_key";
      logger = {
        format = "text";
      };
      root = "/var/lib/step-ca/certs/root_ca.crt";
      tls = {
        cipherSuites = [
          "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
          "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        ];
        maxVersion = 1.3;
        minVersion = 1.2;
        renegotiation = false;
      };
    };
    port = 8443;
    openFirewall = true;
    intermediatePasswordFile = config.sops.secrets."step_ca/password".path;
  };

  services.nginx.virtualHosts."ca.net.dn" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "https://10.0.0.1:8443/";
    };
  };
}
