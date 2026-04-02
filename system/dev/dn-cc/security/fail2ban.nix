{
  self,
  pkgs,
  config,
  ...
}:
let
  serverConfig = self.nixosConfigurations.dn-server.config;
  inherit (serverConfig.networking) domain hostName;
  ntfyScript = pkgs.writeShellScript "" ''
    set -o allexport
    source "${config.sops.secrets."ntfy".path}"
    set +o allexport

    NTFY_URL="https://ntfy.${domain}"
    curl -u "$NTFY_USER" \
         -H "$1" \
         -d "$2" \
         https://ntfy.${domain}/fail2ban
  '';
in
{
  sops.secrets."ntfy" = {
    sopsFile = ../../public/sops/dn-secret.yaml;
    mode = "0600";
  };

  environment.etc = {
    # Define an action that will trigger a Ntfy push notification upon the issue of every new ban
    "fail2ban/action.d/ntfy.local".text = pkgs.lib.mkDefault (
      pkgs.lib.mkAfter ''
        [Definition]
        norestored = true # Needed to avoid receiving a new notification after every restart
        actionban = ${ntfyScript} "Title: <ip> has been banned" "<name> jail has banned <ip> from accessing ${hostName} after <failures> attempts of hacking the system."
      ''
    );
    # Defines a filter that detects URL probing by reading the Nginx access log
    "fail2ban/filter.d/nginx-url-probe.local".text = pkgs.lib.mkDefault (
      pkgs.lib.mkAfter ''
        [Definition]
        failregex = ^<HOST>.*(GET /(wp-|admin|boaform|phpmyadmin|\.env|\.git)|\.(dll|so|cfm|asp)|(\?|&)(=PHPB8B5F2A0-3C92-11d3-A3A9-4C7B08C10000|=PHPE9568F36-D428-11d2-A769-00AA001ACF42|=PHPE9568F35-D428-11d2-A769-00AA001ACF42|=PHPE9568F34-D428-11d2-A769-00AA001ACF42)|\\x[0-9a-zA-Z]{2})
      ''
    );
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "10.20.0.0/24"
    ];
    bantime = "24h";
    bantime-increment = {
      enable = true;
      multipliers = "1 4 64";
      maxtime = "1y";
      overalljails = true;
    };

    jails = {
      nginx-url-probe.settings = {
        enabled = true;
        filter = "nginx-url-probe";
        logpath = "/var/log/nginx/access.log";
        action = ''
          %(action_)s[blocktype=DROP]
                           ntfy'';
        backend = "auto"; # Do not forget to specify this if your jail uses a log file
        maxretry = 5;
        findtime = 600;
      };
      nginx-botsearch.settings = {
        enabled = true;
        filter = "nginx-botsearch";
        logpath = "/var/log/nginx/access.log";
        backend = "auto";
        maxretry = 3;
        findtime = 600;
        action = ''
          %(action_)s[blocktype=DROP]
                           ntfy'';
      };
      nginx-404.settings = {
        enabled = true;
        filter = "nginx-404";
        logpath = "/var/log/nginx/access.log";
        backend = "auto";
        maxretry = 50;
        findtime = 300;
        action = ''
          %(action_)s[blocktype=DROP]
                           ntfy'';
      };
      nginx-http-auth.settings = {
        enabled = true;
        filter = "nginx-http-auth";
        logpath = "/var/log/nginx/error.log";
        backend = "auto";
        maxretry = 5;
        findtime = 600;
        action = ''
          %(action_)s[blocktype=DROP]
                           ntfy'';
      };
      nginx-limit-req.settings = {
        enabled = true;
        filter = "nginx-limit-req";
        logpath = "/var/log/nginx/error.log";
        backend = "auto";
        maxretry = 10;
        findtime = 300;
        action = ''
          %(action_)s[blocktype=DROP]
                           ntfy'';
      };
      nginx-noscript.settings = {
        enabled = true;
        filter = "nginx-noscript";
        logpath = "/var/log/nginx/access.log";
        backend = "auto";
        maxretry = 5;
        findtime = 600;
        action = ''
          %(action_)s[blocktype=DROP]
                           ntfy'';
      };
      nginx-bad-user-agent.settings = {
        enabled = true;
        filter = "nginx-bad-user-agent";
        logpath = "/var/log/nginx/access.log";
        backend = "auto";
        maxretry = 2;
        findtime = 600;
        action = ''
          %(action_)s[blocktype=DROP]
                           ntfy'';
      };

      nginx-login-bruteforce.settings = {
        enabled = true;
        filter = "nginx-login";
        logpath = "/var/log/nginx/access.log";
        backend = "auto";
        maxretry = 5;
        findtime = 600;
        action = ''
          %(action_)s[blocktype=DROP]
                           ntfy'';
      };
    };
  };
}
