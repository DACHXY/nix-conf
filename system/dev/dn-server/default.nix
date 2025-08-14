{
  pkgs,
  lib,
  inputs,
  system,
  username,
  config,
  ...
}:
let
  inherit (lib) optionalAttrs;
  inherit (builtins) toString;
in
{
  imports = [
    (import ../../modules/nvidia.nix {
      nvidia-mode = "offload";
      intel-bus-id = "PCI:0:2:0";
      nvidia-bus-id = "PCI:1:0:0";
    })
    ./sops-conf.nix
    ./boot.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./services.nix
    ./nginx.nix
    ./step-ca.nix
    ../../modules/presets/minimal.nix
    ../../modules/bluetooth.nix
    ../../modules/gc.nix
    ../../modules/mail-server
    (import ../../modules/prometheus.nix {
      fqdn = "metrics.net.dn";
      selfMonitor = true;
      configureNginx = true;
      scrapes = [
        (optionalAttrs config.services.pdns-recursor.enable {
          job_name = "powerdns_recursor";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services.pdns-recursor.api.port}" ];
            }
          ];
        })
      ];
    })
    (import ../../modules/actual.nix {
      fqdn = "actual.net.dn";
    })
    (import ../../modules/nextcloud.nix {
      hostname = "nextcloud.net.dn";
      dataBackupPath = "/mnt/backup_dn";
      dbBackupPath = "/mnt/backup_dn";
    })
    (import ../../modules/vaultwarden.nix {
      domain = "bitwarden.net.dn";
    })
    (import ../../modules/grafana.nix {
      domain = "grafana.net.dn";
      passFile = config.sops.secrets."grafana/password".path;
      smtpHost = config.mail-server.domain;
      smtpDomain = config.mail-server.domain;
      extraSettings = {
        "auth.generic_oauth" =
          let
            OIDCBaseUrl = "https://keycloak.net.dn/realms/master/protocol/openid-connect";
          in
          {
            enabled = true;
            allow_sign_up = true;
            client_id = "grafana";
            client_secret = ''$__file{${config.sops.secrets."grafana/client_secret".path}}'';
            scopes = "openid email profile offline_access roles";
            email_attribute_path = "email";
            login_attribute_path = "username";
            name_attribute_path = "full_name";
            auth_url = "${OIDCBaseUrl}/auth";
            token_url = "${OIDCBaseUrl}/token";
            api_url = "${OIDCBaseUrl}/userinfo";
            role_attribute_path = "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'";
          };
      };
    })
    ../../modules/postgresql.nix
  ];

  environment.systemPackages = with pkgs; [
    openssl
  ];

  mail-server = {
    enable = true;
    mailDir = "~/Maildir";
    caFile = "" + ../../extra/ca.crt;
    virtualMailDir = "/var/mail/vhosts";
    domain = "net.dn";
    rootAlias = "${username}";
    networks = [
      "127.0.0.0/8"
      "10.0.0.0/24"
    ];
    virtual = ''
      admin@net.dn ${username}@net.dn
      postmaster@net.dn ${username}@net.dn
    '';
    openFirewall = true;
    oauth = {
      passwordFile = config.sops.secrets."oauth/password".path;
    };
    ldap = {
      passwordFile = config.sops.secrets."ldap/password".path;
      webEnv = config.sops.secrets."ldap/env".path;
    };
    rspamd = {
      trainerSecret = config.sops.secrets."rspamd-trainer".path;
    };
  };

  home-manager = {
    users."${username}" = {
      imports = [
        ../../../home/user/config.nix
        ../../../home/user/direnv.nix
        ../../../home/user/environment.nix
        ../../../home/user/nvim.nix
        ../../../home/user/shell.nix
        ../../../home/user/tmux.nix
        ../../../home/user/yazi.nix
        {
          home.packages = with pkgs; [
            inputs.ghostty.packages.${system}.default
            (python3.withPackages (
              p: with p; [
                pip
              ]
            ))
          ];
        }

        # Git
        (import ../../../home/user/git.nix {
          inherit username;
          email = "danny10132024@gmail.com";
        })
      ];
    };
  };
}
