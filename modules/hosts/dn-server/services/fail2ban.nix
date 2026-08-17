{
  configurations.nixos.dn-server.module =
    { pkgs, ... }@nixosArgs:
    let
      nginxAccessLogPath = "/var/log/nginx/access.log";
    in
    {
      environment.etc = {
        "fail2ban/filter.d/nginx-url-probe.local".text = pkgs.lib.mkDefault (
          pkgs.lib.mkAfter ''
            [Definition]
            failregex = ^<HOST>.*(GET /(wp-|admin|boaform|phpmyadmin|\.env|\.git)|\.(dll|so|cfm|asp)|(\?|&)(=PHPB8B5F2A0-3C92-11d3-A3A9-4C7B08C10000|=PHPE9568F36-D428-11d2-A769-00AA001ACF42|=PHPE9568F35-D428-11d2-A769-00AA001ACF42|=PHPE9568F34-D428-11d2-A769-00AA001ACF42)|\\x[0-9a-zA-Z]{2})
          ''
        );
        "fail2ban/filter.d/nginx-444.local".text = pkgs.lib.mkDefault (
          pkgs.lib.mkAfter ''
            [Definition]
            failregex = ^<HOST> .* \b444\b
            ignoreregex =
          ''
        );
      };
      services.fail2ban = {
        enable = true;
        maxretry = 5;
        ignoreIP = nixosArgs.config.server-rules.rule.default.allowed.ipv4;
        bantime = "128h";
        bantime-increment = {
          enable = true;
          multipliers = "8 64";
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
          };
          nginx-404.settings = {
            enabled = true;
            filter = "nginx-404";
            logpath = nginxAccessLogPath;
            backend = "auto";
            maxretry = 10;
            findtime = 300;
          };
          nginx-http-auth.settings = {
            enabled = true;
            filter = "nginx-http-auth";
            logpath = "/var/log/nginx/error.log";
            backend = "auto";
            maxretry = 5;
            findtime = 600;
          };
          nginx-limit-req.settings = {
            enabled = true;
            filter = "nginx-limit-req";
            logpath = "/var/log/nginx/error.log";
            backend = "auto";
            maxretry = 10;
            findtime = 300;
          };
          nginx-noscript.settings = {
            enabled = true;
            filter = "nginx-noscript";
            logpath = nginxAccessLogPath;
            backend = "auto";
            maxretry = 5;
            findtime = 600;
          };
          nginx-bad-user-agent.settings = {
            enabled = true;
            filter = "nginx-bad-user-agent";
            logpath = nginxAccessLogPath;
            backend = "auto";
            maxretry = 2;
            findtime = 600;
          };
          nginx-login-bruteforce.settings = {
            enabled = true;
            filter = "nginx-login";
            logpath = nginxAccessLogPath;
            backend = "auto";
            maxretry = 5;
            findtime = 600;
          };
          nginx-444.settings = {
            enabled = true;
            filter = "nginx-444";
            logpath = nginxAccessLogPath;
            backend = "auto";
            maxretry = 2;
            findtime = 600;
          };
        };
      };
    };
}
