{
  config,
  inputs,
  system,
  ...
}:
let
  listenPort = 30098;
in
{
  services.atticd = {
    enable = true;
    environmentFile = config.sops.secrets."atticd/secret".path;
    settings = {
      listen = "127.0.0.1:${toString listenPort}";
      jwt = { };

      chunking = {
        nar-size-threshold = 64 * 1024;
        min-size = 16 * 1024;
        avg-size = 64 * 1024;
        max-size = 256 * 1024;
      };
    };
  };

  services.nginx.virtualHosts."cache.${config.networking.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString listenPort}";
    extraConfig = ''
      client_max_body_size 10240M;
    '';
  };

  environment.systemPackages = with inputs.attic.packages.${system}; [
    attic-server
    attic
  ];
}
