{
  config,
  inputs,
  ...
}:
let
  inherit (config.flake.public.config.services) stalwart webmail;
  inherit (config.flake.public.config) domain;
in
{
  configurations.nixos.dn-server.module =
    {
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.services.ihasmail;
    in
    {
      imports = [
        inputs.ihasmail.nixosModules.default
      ];

      sops.secrets."ihasmail" = { };

      services.ihasmail = {
        enable = true;
        package = inputs.ihasmail.packages.${pkgs.stdenv.hostPlatform.system}.default;
        openFirewall = true;
        port = 30092;
        stalwartUrl = stalwart.endpoint;
        appSecretFile = config.sops.secrets."ihasmail".path;
      };

      services.nginx.virtualHosts."${webmail.hostname}" = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://127.0.0.1:${toString cfg.port}/";
      };
    };
}
