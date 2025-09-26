{
  extreAllowList ? [ ],
  ...
}:
{

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "192.168.0.0/16"
    ]
    ++ extreAllowList;
    bantime = "24h";
    bantime-increment = {
      enable = true;
      multipliers = "8 64";
      maxtime = "1y";
      overalljails = true;
    };
    jails =
      let
        nginxLogPath = "/var/log/nginx/error.log*";
      in
      {
        sshd.settings = {
          logPath = "";
          filter = "sshd";
          action = ''nftables-multiport[name="sshd", port="ssh,30072"]'';
          backend = "systemd";
          findtime = 600;
          bantime = 600;
          maxretry = 5;
        };
        nginx-error-common.settings = {
          logPath = nginxLogPath;
          filter = "nginx-error-common";
          action = ''nftables-multiport[name=HTTP, port="http,https"]'';
          backend = "auto";
          findtime = 600;
          bantime = 600;
          maxretry = 5;
        };
        nginx-forbidden.settings = {
          logPath = nginxLogPath;
          filter = "nginx-forbidden";
          action = ''nftables-multiport[name=HTTP, port="http,https"]'';
          backend = "auto";
          findtime = 600;
          bantime = 600;
          maxretry = 5;
        };
      };
  };
}
