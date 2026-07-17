{ config, ... }:
let
  ntfyHostname = config.flake.public.config.services.ntfy.hostname;
in
{
  configurations.nixos.dn-cc.module =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (config.networking) hostName;
      allowedIPv4 = config.server-rules.rule.default.allowed.ipv4;
      ntfyScript = pkgs.writeShellScript "" ''
        set -o allexport
        source "${config.sops.secrets."ntfy".path}"
        set +o allexport

        NTFY_URL="https://${ntfyHostname}"
        ${pkgs.curl}/bin/curl -u "$NTFY_USER" \
             -H "$1" \
             -d "$2" \
             "$NTFY_URL/fail2ban"
      '';
      nginxAccessLogPath = "/var/log/nginx/access.log";
      enableNotify = false;
      action =
        if enableNotify then
          ''
            %(action_)s[blocktype=DROP]
                                       ntfy''
        else
          "";
    in
    {
      sops.secrets."ntfy" = {
        sopsFile = ../../../users/danny/secret.yaml;
        mode = "0600";
      };

      environment.etc = {
        # Define an action that will trigger a Ntfy push notification upon the issue of every new ban
        "fail2ban/action.d/ntfy.local".text = pkgs.lib.mkDefault (
          pkgs.lib.mkAfter ''
            [Definition]
            norestored = 1
            actionban = ${ntfyScript} "Title: \"<ip>\" has been banned" "\"<name>\" jail has banned \"<ip>\" from accessing [${hostName}] after <failures> attempts of hacking the system."
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
        ignoreIP = allowedIPv4;
        bantime = "24h";
        bantime-increment = {
          enable = true;
          multipliers = "1 32 64";
          maxtime = "1y";
          overalljails = true;
        };

        jails = {
          sshd.settings = {
            backend = "systemd";
            mode = "aggressive";
          };
          nginx-url-probe.settings = {
            enabled = true;
            filter = "nginx-url-probe";
            logpath = nginxAccessLogPath;
            action = "";
            backend = "auto";
            maxretry = 2;
            findtime = 600;
          };
          nginx-botsearch.settings = {
            enabled = true;
            filter = "nginx-botsearch";
            logpath = nginxAccessLogPath;
            backend = "auto";
            maxretry = 2;
            findtime = 600;
            action = action;
          };
          nginx-404.settings = {
            enabled = true;
            filter = "nginx-404";
            logpath = nginxAccessLogPath;
            backend = "auto";
            maxretry = 10;
            findtime = 300;
            action = action;
          };
          nginx-http-auth.settings = {
            enabled = true;
            filter = "nginx-http-auth";
            logpath = "/var/log/nginx/error.log";
            backend = "auto";
            maxretry = 5;
            findtime = 600;
            action = action;
          };
          nginx-limit-req.settings = {
            enabled = true;
            filter = "nginx-limit-req";
            logpath = "/var/log/nginx/error.log";
            backend = "auto";
            maxretry = 10;
            findtime = 300;
            action = action;
          };
          nginx-noscript.settings = {
            enabled = true;
            filter = "nginx-noscript";
            logpath = nginxAccessLogPath;
            backend = "auto";
            maxretry = 5;
            findtime = 600;
            action = action;
          };
          nginx-bad-user-agent.settings = {
            enabled = true;
            filter = "nginx-bad-user-agent";
            logpath = nginxAccessLogPath;
            backend = "auto";
            maxretry = 2;
            findtime = 600;
            action = action;
          };
          nginx-login-bruteforce.settings = {
            enabled = true;
            filter = "nginx-login";
            logpath = nginxAccessLogPath;
            backend = "auto";
            maxretry = 5;
            findtime = 600;
            action = action;
          };
        };
      };
    };
}
