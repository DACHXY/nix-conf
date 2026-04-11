{
  lib,
  self,
  pkgs,
  config,
  ...
}:
let
  inherit (self.nixosConfigurations.dn-server.config.networking) domain;
  inherit (builtins) toJSON;

  matrixDomain = "matrix.${domain}";
  port = 8008;

  # === matrix-authentication-service === #
  masPort = 8199;
  masDomain = "matrix-auth.${domain}";
  masDataDir = "/var/lib/matrix-authentication-service";
  masOwner = "matrix-authentication-service";

  elementDomain = "element.${domain}";
  mailDomain = "mx2.${domain}";

  clientConfig = {
    "m.homeserver" = {
      base_url = "https://${matrixDomain}";
      server_name = domain;
    };
    "m.identity_server" = { };
    "org.matrix.msc3575.proxy" = {
      url = "https://${matrixDomain}";
    };
    "org.matrix.msc4143.rtc_foci" = [
      {
        type = "livekit";
        livekit_service_url = "https://${matrixDomain}/livekit/jwt";
      }
    ];
  };
  serverConfig = {
    "m.server" = "${matrixDomain}:443";
  };
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${toJSON data}';
  '';
  owner = "matrix-synapse";

  livekitKeyFile = "/run/livekit.key";
in
{
  sops.secrets = {
    "matrix/turn-password" = {
      inherit owner;
    };
    "matrix/admin-token" = {
      inherit owner;
    };
    "matrix/smtp-user" = {
      inherit owner;
    };
    "matrix/smtp-pass" = {
      inherit owner;
    };
    "matrix/mas-client-secret" = {
      owner = masOwner;
    };
    "matrix/encrypt-key" = {
      owner = masOwner;
    };
    "matrix/encrypt-rsa" = {
      owner = masOwner;
    };
  };

  sops.templates."matrix-synapse-secrets.yaml" = {
    inherit owner;
    restartUnits = [ "matrix-synapse.service" ];
    content = ''
      matrix_authentication_service:
        enabled: true
        endpoint: http://127.0.0.1:${toString masPort}/
        secret: "${config.sops.placeholder."matrix/admin-token"}"
      turn_shared_secret: ${config.sops.placeholder."matrix/turn-password"} 

      email:
        smtp_host: ${mailDomain}
        smtp_port: 465
        smtp_user: ${config.sops.placeholder."matrix/smtp-user"}
        smtp_pass: ${config.sops.placeholder."matrix/smtp-pass"}
        force_tls: true
        notif_from: $(app)s <${config.sops.placeholder."matrix/smtp-user"}@${domain}>
        app_name: Matrix
        client_base_url: https://${matrixDomain}
        invite_client_location: https://${elementDomain}
    '';
  };

  sops.templates."mas-config.yaml" = {
    owner = masOwner;
    restartUnits = [ "${masOwner}.service" ];
    content = ''
      http:
        public_base: https://${masDomain}/
        listeners:
          - name: web
            resources:
              - name: discovery
              - name: human
              - name: oauth
              - name: compat
              - name: graphql
              - name: assets
            binds:
              - host: 127.0.0.1
                port: ${toString masPort}
        trusted_proxies:
          - 192.168.0.0/16
          - 172.16.0.0/12
          - 10.0.0.0/10
          - 127.0.0.1/8
          - fd00::/8
          - ::1/128

      matrix:
        kind: synapse
        homeserver: "${matrixDomain}"
        endpoint: "https://${matrixDomain}"
        secret: "${config.sops.placeholder."matrix/admin-token"}"

      secrets:
        encryption: ${config.sops.placeholder."matrix/encrypt-key"}
        keys:
          - kid: "iv1aShae"
            key_file: ${config.sops.secrets."matrix/encrypt-rsa".path}

      upstream_oauth2:
        providers:
          - id: "01KNMHBD2FFJG3R61M37PPW5P0"
            issuer: "https://login.${domain}/realms/master"
            human_name: "Keycloak"
            token_endpoint_auth_method: client_secret_basic
            client_id: "matrix-authentication-service"
            client_secret: "${config.sops.placeholder."matrix/mas-client-secret"}"
            scope: "openid profile email"
            claims_imports:
              localpart:
                action: force
                on_conflict: set
                template: "{{ user.preferred_username }}"
              displayname:
                action: suggest
                template: "{{ user.name }}"
              email:
                action: suggest
                template: "{{ user.email }}"

      passwords:
        enabled: false

      database:
        uri: postgresql:///matrix-authentication-service?host=/run/postgresql
        max_connections: 10
        min_connections: 0
        connect_timeout: 30
        idle_timeout: 600
        max_lifetime: 1800
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8448 ];

  # ==== MAS ==== #
  # MAS user and group
  users.users.matrix-authentication-service = {
    isSystemUser = true;
    group = "matrix-authentication-service";
    home = masDataDir;
    description = "Matrix Authentication Service";
  };
  users.groups.matrix-authentication-service = { };

  # MAS systemd service
  systemd.services.matrix-authentication-service = {
    description = "Matrix Authentication Service";
    after = [
      "network.target"
      "postgresql.service"
    ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "matrix-authentication-service";
      Group = "matrix-authentication-service";

      StateDirectory = "matrix-authentication-service";
      WorkingDirectory = masDataDir;
      ExecStart = "${pkgs.matrix-authentication-service}/bin/mas-cli server --config ${
        config.sops.templates."mas-config.yaml".path
      }";
      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ masDataDir ];
      CapabilityBoundingSet = "";
      SystemCallFilter = [ "@system-service" ];
      SystemCallErrorNumber = "EPERM";
    };
  };

  # ==== Synapse ==== #
  systemd.services.matrix-synapse = {
    after = [
      "matrix-authentication-service.service"
    ];
    wants = [ "matrix-authentication-service.service" ];
  };

  services.matrix-synapse = {
    enable = true;
    configureRedisLocally = true;
    extras = [ "oidc" ];
    extraConfigFiles = [
      config.sops.templates."matrix-synapse-secrets.yaml".path
    ];
    settings = {
      server_name = domain;
      web_client_location = "https://${elementDomain}/";
      public_baseurl = "https://${matrixDomain}";
      admin_contact = "mailto:admin@${domain}";
      auto_join_rooms = [
        "#welcome:dnywe.com"
      ];
      max_avatar_size = "10M";
      url_preview_enabled = true;
      url_preview_accept_language = [
        "zh-TW"
        "en;q=0.9"
      ];
      url_preview_ip_range_whitelist = [
        "10.20.0.2"
      ];
      url_preview_ip_range_blacklist = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "100.64.0.0/10"
        "192.0.0.0/24"
        "169.254.0.0/16"
        "192.88.99.0/24"
        "198.18.0.0/15"
        "192.0.2.0/24"
        "198.51.100.0/24"
        "203.0.113.0/24"
        "224.0.0.0/4"
        "::1/128"
        "fe80::/10"
        "fc00::/7"
        "2001:db8::/32"
        "ff00::/8"
        "fec0::/10"
      ];

      user_directory = {
        enabled = true;
        search_all_users = true;
        prefer_local_users = true;
      };

      room_list_publication_rules = [
        {
          user_id = "@*:${domain}";
          action = "allow";
        }
      ];

      serve_server_wellknown = false;
      serve_client_wellknown = false;

      listeners = [
        {
          inherit port;
          bind_addresses = [ "127.0.0.1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
                "openid"
              ];
              compress = false;
            }
          ];
        }
      ];

      database = {
        name = "psycopg2";
        allow_unsafe_locale = true;
        args = {
          user = "matrix-synapse";
          database = "matrix-synapse";
          host = "/run/postgresql";
        };
      };

      max_upload_size = "100M";
      enable_registration = false;
      enable_metrics = true;

      turn_uris = [
        "turn:coturn.${domain}:3478?transport=udp"
        "turn:coturn.${domain}:3478?transport=tcp"
      ];
      turn_username = "matrix";
      turn_user_lifetime = "1h";
      turn_allow_guests = false;

      trusted_key_servers = [
        {
          server_name = "matrix.org";
        }
      ];

      matrix_rtc.transports = [
        {
          type = "livekit";
          livekit_service_url = "https://${matrixDomain}/livekit/jwt";
        }
      ];
    };
  };

  # ==== Database ==== #
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "matrix-synapse"
      "matrix-authentication-service"
    ];
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensureDBOwnership = true;
      }
      {
        name = "matrix-authentication-service";
        ensureDBOwnership = true;
      }
    ];
  };

  # ==== Livekit ==== #
  services.livekit = {
    enable = true;
    openFirewall = true;
    settings.room.auto_create = true;
    keyFile = livekitKeyFile;
  };

  services.lk-jwt-service = {
    enable = true;
    port = 8198;
    livekitUrl = "wss://${matrixDomain}/livekit/sfu";
    keyFile = livekitKeyFile;
  };

  # generate the key when needed
  systemd.services.livekit-key = {
    before = [
      "lk-jwt-service.service"
      "livekit.service"
    ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [
      livekit
      coreutils
      gawk
    ];
    script = ''
      echo "Key missing, generating key"
      echo "lk-jwt-service: $(livekit-server generate-keys | tail -1 | awk '{print $3}')" > "${livekitKeyFile}"
    '';
    serviceConfig.Type = "oneshot";
    unitConfig.ConditionPathExists = "!${livekitKeyFile}";
  };

  # restrict access to livekit room creation to a homeserver
  systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS = "${matrixDomain}";

  services.nginx.virtualHosts = {
    ${domain} = {
      useACMEHost = domain;
      forceSSL = true;

      locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
      locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
    };

    ${matrixDomain} = {
      useACMEHost = domain;
      forceSSL = true;

      locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
      locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;

      locations."^~ /livekit/jwt/" = {
        priority = 400;
        proxyPass = "http://127.0.0.1:${toString config.services.lk-jwt-service.port}/";
      };
      locations."^~ /livekit/sfu/" = {
        extraConfig = ''
          proxy_send_timeout 120;
          proxy_read_timeout 120;
          proxy_buffering off;

          proxy_set_header Accept-Encoding gzip;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
        '';
        priority = 400;
        proxyPass = "http://[::1]:${toString config.services.livekit.settings.port}/";
        proxyWebsockets = true;
      };

      locations."~ ^(/_matrix|/_synapse/client|/_synapse/mas)" = {
        recommendedProxySettings = false;
        proxyPass = "http://127.0.0.1:${toString port}";
        extraConfig = ''
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Host $host;
          client_max_body_size 100M;
        '';
      };

      locations."~ ^/_matrix/client/(.*)/(login|logout|refresh)" = {
        recommendedProxySettings = false;
        proxyPass = "http://127.0.0.1:${toString masPort}";
        extraConfig = ''
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };

    "${masDomain}" = {
      useACMEHost = domain;
      forceSSL = true;

      locations."/" = {
        recommendedProxySettings = false;
        proxyPass = "http://127.0.0.1:${toString masPort}";
        extraConfig = ''
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };

    # web client
    "${elementDomain}" = {
      useACMEHost = domain;
      forceSSL = true;

      root = pkgs.element-web.override {
        conf = {
          default_server_config = clientConfig;
          default_country_code = "TW";
          show_labs_settings = true;
          default_theme = "dark";
          room_directory = {
            servers = [
              "${matrixDomain}"
              "matrix.org"
            ];
          };
        };
      };
    };
  };
}
