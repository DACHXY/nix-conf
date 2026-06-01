{
  flake.public.config =
    let
      myDomain = "dnywe.com";
    in
    {
      domain = myDomain;
      services = {
        netbird = rec {
          hostname = "netbird.${myDomain}";
          endpoint = "https://${hostname}";
        };
        nextcloud = rec {
          hostname = "nextcloud.${myDomain}";
          endpoint = "https://${hostname}";
        };
        forgejo = rec {
          hostname = "git.${myDomain}";
          endpoint = "https://${hostname}";
          sshEndpoint = "ssh://${hostname}";
        };
        actual = rec {
          hostname = "actual.${myDomain}";
          endpoint = "https://${hostname}";
        };
        oidc = rec {
          hostname = "login.${myDomain}";
          endpoint = "https://${hostname}";
          realm = "master";
          oidcConfigEndpoint = "${endpoint}/realms/${realm}/.well-known/openid-configuration";
        };
      };
    };
}
