{
  domain,
  idpSecret,
  dataStoreEncryptionKey,
  coturnPassFile,
  ...
}:
let
  port = 51820;
in
{
  services.netbird = {
    server = {
      enable = true;
      domain = "netbird.${domain}";
      enableNginx = true;
      management = {
        oidcConfigEndpoint = "https://keycloak.net.dn/realms/master/.well-known/openid-configuration";
        settings = {
          DataStoreEncryptionKey = {
            _secret = dataStoreEncryptionKey;
          };
          TURNConfig = {
            Secret = {
              _secret = idpSecret;
            };
          };
          IdpManagerConfig = {
            ClientConfig = {
              ClientID = "netbird-backend";
              ClientSecret = {
                _secret = idpSecret;
              };
            };
          };
        };
      };
      coturn = {
        user = "netbird";
        passwordFile = coturnPassFile;
        enable = true;
      };
      dashboard.settings = {
        USE_AUTH0 = false;
        AUTH_AUTHORITY = "https://keycloak.net.dn/realms/master";
        AUTH_CLIENT_ID = "netbird";
        AUTH_AUDIENCE = "netbird";
        AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
      };
    };
    clients.default = {
      inherit port;
      openFirewall = true;
      name = "netbird";
      interface = "wt0";
      hardened = true;
      dns-resolver.address = "10.0.0.1";
    };
  };

  services.nginx.virtualHosts."netbird.${domain}" = {
    enableACME = true;
    forceSSL = true;
  };
}
