{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  mkCondition = (
    condition: ithen: ielse: [
      {
        "if" = condition;
        "then" = ithen;
      }
      { "else" = ielse; }
    ]
  );

  rspamdWebPort = 11333;
  rspamdPort = 31009;
  domain = "dnywe.com";
  fqdn = "mx1.dnywe.com";

  rspamdSecretFile = config.sops.secrets."rspamd".path;
  rspamdSecretPath = "/run/rspamd/rspamd-controller-password.inc";
in
{
  networking.firewall.allowedTCPPorts = [ 8080 ];

  imports = [
    (import ../../../modules/stalwart.nix {
      inherit domain;

      enableNginx = false;
      adminPassFile = config.sops.secrets."stalwart/adminPassword".path;
      certs."default" = {
        default = true;
        cert = "%{file:${config.security.acme.certs.${fqdn}.directory}/cert.pem}%";
        private-key = "%{file:${config.security.acme.certs.${fqdn}.directory}/key.pem}%";
      };
      ldapConf = {
        type = "ldap";
        url = "ldaps://ldap.net.dn";
        tls.enable = true;
        timeout = "30s";
        base-dn = "ou=people,dc=net,dc=dn";
        attributes = {
          name = "uid";
          email = "mail";
          email-alias = "mailRoutingAddress";
          secret = "userPassword";
          description = [
            "cn"
            "description"
          ];
          class = "objectClass";
          groups = [ "memberOf" ];
        };
        filter = {
          name = "(&(objectClass=inetOrgPerson)(|(uid=?)(mail=?)(mailRoutingAddress=?)))";
          email = "(&(objectClass=inetOrgPerson)(|(mailRoutingAddress=?)(mail=?)))";
        };
        bind = {
          dn = "cn=admin,dc=net,dc=dn";
          secret = "%{file:${config.sops.secrets."stalwart/ldap".path}}%";
          auth = {
            method = "default";
          };
        };
      };
    })
  ];

  services.stalwart-mail.settings.spam-filter.enable = !config.services.rspamd.enable;

  services.stalwart-mail.settings.session.milter."rspamd" = mkIf config.services.rspamd.enable {
    enable = mkCondition "listener = 'smtp'" true false;
    hostname = "127.0.0.1";
    port = rspamdPort;
    stages = [
      "connect"
      "ehlo"
      "mail"
      "rcpt"
      "data"
    ];
    tls = false;
    allow-invalid-certs = false;
    options = {
      tempfail-on-error = true;
      max-response-size = 52428800; # 50mb
      version = 6;
    };
  };

  services.rspamd = {
    enable = true;
    locals = {
      "redis.conf".text = ''
        servers = "${config.services.redis.servers.rspamd.unixSocket}";
      '';
      "classifier-bayes.conf".text = ''
        backend = "redis";
        autolearn = true;
      '';
      "dkim_signing.conf".text = ''
        enabled = false;
      '';
      "milter_headers.conf".text = ''
        enabled = true;
        extended_spam_headers = true;
        skip_local = false;
        use = ["x-spamd-bar", "x-spam-level", "x-spam-status", "authentication-results", "x-spamd-result"];
        authenticated_headers = ["authentication-results"];
      '';
    };
    localLuaRules =
      pkgs.writeText "rspamd-local.lua"
        # lua
        ''
          -- Temporary fix for double dot issue rspamd#5273
          local lua_util = require("lua_util")

          rspamd_config.UNQUALIFY_SENDER_HOSTNAME = {
            callback = function(task)
              local hn = task:get_hostname()
              if not hn then return end
              local san_hn = string.gsub(hn, "%.$", "")
              if hn ~= san_hn then
                task:set_hostname(san_hn)
              end
            end,
            type = "prefilter",
            priority = lua_util.symbols_priorities.top + 1,
          }
        '';
    workers = {
      rspamd_proxy = {
        type = "rspamd_proxy";
        includes = [ "$CONFDIR/worker-proxy.inc" ];
        bindSockets = [
          "*:${toString rspamdPort}"
        ];
        extraConfig = ''
          self_scan = yes;
        '';
      };
      controller = {
        type = "controller";
        includes = [
          "$CONFDIR/worker-controller.inc"
        ];
        extraConfig = ''
          .include(try=true; priority=1,duplicate=merge) "${rspamdSecretPath}"
        '';
        bindSockets = [ "127.0.0.1:${toString rspamdWebPort}" ];
      };
    };
    overrides."whitelist.conf".text = ''
      whiltelist_from {
        ${domain} = true;
      }
    '';
  };

  systemd.services.rspamd = mkIf config.services.rspamd.enable {
    path = [
      pkgs.rspamd
      pkgs.coreutils
    ];
    serviceConfig = {
      ExecStartPre = [
        "${pkgs.writeShellScript "generate-rspamd-passwordfile" ''
          RSPAMD_PASSWORD_HASH=$(rspamadm pw --password $(cat ${rspamdSecretFile}))
          echo "enable_password = \"$RSPAMD_PASSWORD_HASH\";" > ${rspamdSecretPath} 
          chmod 770 "${rspamdSecretPath}" 
        ''}"
      ];
    };
  };

  services.redis.servers.rspamd = {
    enable = true;
    port = 0;
    user = config.services.rspamd.user;
  };

  security.acme = {
    acceptTerms = true;
    certs."${fqdn}" = {
      inheritDefaults = false;
      group = config.systemd.services.stalwart-mail.serviceConfig.Group;
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      server = "https://acme-v02.api.letsencrypt.org/directory";
      validMinDays = 30;
      email = "dachxy@${domain}";
      extraDomainNames = [ domain ];
      environmentFile = config.sops.secrets."cloudflare/secret".path;
      postRun = ''
        systemctl reload stalwart-mail
      '';
    };
  };

  services.mail-ntfy-server = {
    enable = true;
    settings = {
      NTFY_URL = "https://ntfy.net.dn";
      NTFY_TOPIC = "dachxy-mail";
      NTFY_RCPTS = [ "dachxy@dnywe.com" ];
      HOST = "127.0.0.1";
      PORT = 31010;
    };
    environmentFiles = [
      config.sops.secrets."ntfy".path
    ];
  };
}
