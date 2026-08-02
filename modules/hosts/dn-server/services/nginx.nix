{
  configurations.nixos.dn-server.module =
    {
      pkgs,
      ...
    }:
    {
      services.nginx = {
        enable = true;
        enableReload = true;
        additionalModules = with pkgs.nginxModules; [ geoip2 ];
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;
        recommendedProxySettings = true;

        prependConfig = ''
          worker_processes auto;
          worker_rlimit_nofile 65535;
        '';

        eventsConfig = /* nginx */ ''
          worker_connections 65535;
        '';
      };
    };
}
