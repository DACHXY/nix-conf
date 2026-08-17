{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services) coturn;
  matrixName = "matrix";
in
{
  configurations.nixos.dn-cc.module =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (config.sops) secrets;
      inherit (lib) mkAfter getExe;
    in
    {
      sops.secrets."netbird/coturn/password" = {
        owner = "turnserver";
      };

      services.coturn = {
        extraConfig = mkAfter ''
          user=${matrixName}:@${matrixName}-password@
        '';
        cert = "@cert@";
        pkey = "@pkey@";
      };

      systemd.services.coturn =
        let
          dir = config.security.acme.certs.${domain}.directory;
        in
        {
          serviceConfig.LoadCredential = [
            "cert.pem:${dir}/fullchain.pem"
            "pkey.pem:${dir}/key.pem"
          ];

          preStart = mkAfter ''
            ${getExe pkgs.replace-secret} @${matrixName}-password@ ${
              secrets."netbird/coturn/password".path
            } /run/coturn/turnserver.cfg

            # Certs
            ${getExe pkgs.replace-secret} @cert@ <(echo -n "$CREDENTIALS_DIRECTORY/cert.pem") /run/coturn/turnserver.cfg
            ${getExe pkgs.replace-secret} @pkey@ <(echo -n "$CREDENTIALS_DIRECTORY/pkey.pem") /run/coturn/turnserver.cfg
          '';
        };

      services.netbird.server.coturn = {
        domain = coturn.hostname;
        enable = true;
        passwordFile = secrets."netbird/coturn/password".path;
      };
    };
}
