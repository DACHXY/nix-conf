{ config, ... }:
{
  imports = [
    (import ../../../modules/paperless-ngx.nix {
      domain = "paperless.net.dn";
      passwordFile = config.sops.secrets."paperless/adminPassword".path;
    })
  ];

  # OIDC
  services.paperless = {
    settings = {
      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_SOCIAL_AUTO_SIGNUP = true;
      PAPERLESS_SOCIAL_ALLOW_SIGNUPS = true;
    };
    environmentFile = config.sops.secrets."paperless/envFile".path;
  };
}
