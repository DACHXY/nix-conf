{
  configurations.nixos.dn-cscc.module = {
    services.nginx = {
      enable = true;
      defaultHTTPListenPort = 30012;
      defaultSSLListenPort = 30013;
      virtualHosts = {
        "localhost" = {
          locations."/".extraConfig = ''
            return 200 "Hello there";
          '';
        };
      };
    };
  };
}
