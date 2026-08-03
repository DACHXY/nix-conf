{
  configurations.nixos.dn-cscc.module = {
    services.traefik = {
      enable = true;
      staticConfigOptions = {
        api = {
          dashboard = true;
          insecure = true;
        };
        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
          };
          websecure = {
            address = ":443";
          };
          dashboard = {
            address = ":30013";
          };
        };
      };
      dynamicConfigOptions = {
        http = {
          routers = {
            dashboard = {
              rule = "PathPrefix(`/`)";
              entryPoints = [
                "dashboard"
              ];
              service = "api@internal";
            };
          };
        };
        services = {
          nginx-fallback = {
            loadBalancer.servers = [ { url = "http://127.0.0.1:30012"; } ];
          };
        };
      };
    };
  };
}
