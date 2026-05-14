{
  flake.public.config =
    let
      myDomain = "dnywe.com";
    in
    {
      services = {
        netbird = rec {
          domain = "netbird.${myDomain}";
          endpoint = "https://${domain}";
        };
        nextcloud = rec {
          domain = "nextcloud.${myDomain}";
          endpoint = "https://${domain}";
        };
        forgejo = rec {
          domain = "git.${myDomain}";
          endpoint = "https://${domain}";
        };
        oidc = rec {
          domain = "login.${myDomain}";
          endpoint = "https://${domain}";
          realm = "master";
          oidcConfigEndpoint = "${endpoint}/realms/${realm}/.well-known/openid-configuration";
        };
      };
    };
}
