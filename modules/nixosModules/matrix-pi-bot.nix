# Matrix ⇄ pi bridge: talk to a pi coding agent from a Matrix room.
#
# Import as `nixos.matrix-pi-bot`, then:
#
#   services.matrix-pi-bot = {
#     enable = true;
#     userId = "@pi:dnywe.com";
#     allowedUsers = [ "@me:dnywe.com" ];
#     workspace = "/home/danny/projects/nix-conf";
#   };
#   sops.secrets."matrix/pi-bot-token".owner = "danny";
#
# The bot reads its access token from `tokenFile` at start and refuses to
# answer anybody who is not in `allowedUsers`: every allowed message is
# executed by a coding agent that can run shell commands as `user`, so the
# whitelist is the only thing standing between a chat message and code
# execution on this machine.
{
  flake.modules.nixos.matrix-pi-bot =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.matrix-pi-bot;
      inherit (lib)
        mkEnableOption
        mkOption
        mkIf
        types
        optionalAttrs
        ;

      # writePython3 (without the Bin suffix) returns a symlink straight to the
      # script, so `${bridge}/bin/matrix-pi-bot` would not exist.
      bridge = pkgs.writers.writePython3Bin "matrix-pi-bot" {
        libraries = [ pkgs.python3Packages.matrix-nio ];
        flakeIgnore = [
          "E203"
          "E265"
          "E501"
        ];
      } (builtins.readFile ../matrix-pi-bot/bot.py);

      runtimePath = lib.makeBinPath (
        [
          cfg.package
          pkgs.nix
          pkgs.git
          pkgs.bash
          pkgs.coreutils
          pkgs.gnused
          pkgs.gnugrep
          pkgs.ripgrep
          pkgs.findutils
        ]
        ++ cfg.extraPackages
      );
    in
    {
      options.services.matrix-pi-bot = {
        enable = mkEnableOption "the Matrix ⇄ pi bridge";

        package = mkOption {
          type = types.package;
          default = pkgs.llm-agents.pi;
          defaultText = lib.literalExpression "pkgs.llm-agents.pi";
          description = "pi package the bridge drives.";
        };

        homeserverUrl = mkOption {
          type = types.str;
          example = "https://matrix.dnywe.com";
          description = "Base URL of the Matrix homeserver (client-server API).";
        };

        userId = mkOption {
          type = types.str;
          example = "@pi:dnywe.com";
          description = "Full Matrix id of the bot account.";
        };

        tokenFile = mkOption {
          type = types.path;
          default = "/run/secrets/matrix/pi-bot-token";
          description = "File containing the bot's access token (sops-nix secret).";
        };

        allowedUsers = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "@danny:dnywe.com" ];
          description = ''
            Matrix ids allowed to talk to the agent. Empty means nobody — the
            bot stays silent until a user is listed here.
          '';
        };

        allowedRooms = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Room ids the bot answers in. Empty means every room it was invited
            to by an allowed user.
          '';
        };

        workspace = mkOption {
          type = types.str;
          default = "/home/${cfg.user}";
          description = "Working directory for the agent (its tools act here).";
        };

        user = mkOption {
          type = types.str;
          default = "danny";
          description = "User the agent runs as.";
        };

        group = mkOption {
          type = types.str;
          default = "users";
          description = "Group the agent runs as.";
        };

        stateDir = mkOption {
          type = types.str;
          default = "/var/lib/matrix-pi-bot";
          description = "Sync state and per-room pi sessions.";
        };

        piArgs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [
            "--model"
            "sonnet:high"
          ];
          description = "Extra flags passed to every pi invocation.";
        };

        timeoutSeconds = mkOption {
          type = types.int;
          default = 900;
          description = "Wall clock limit for a single turn; the process tree is killed after it.";
        };

        stream = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Show the answer as it is generated: one Matrix message edited in
            place (m.replace) while the agent streams text.
          '';
        };

        streamIntervalSeconds = mkOption {
          type = types.float;
          default = 2.0;
          description = ''
            Minimum seconds between two streaming edits. Matrix counts edits as
            messages and Synapse's stock rate limit is 0.2/s (burst 10), so do
            not go much below 2.
          '';
        };

        logLevel = mkOption {
          type = types.str;
          default = "INFO";
          description = "Python log level for the bridge.";
        };

        extraPackages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Extra binaries added to the service PATH.";
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.allowedUsers != [ ];
            message = "services.matrix-pi-bot.allowedUsers must name at least one Matrix id; the bot executes code as ${cfg.user}.";
          }
        ];

        systemd.tmpfiles.rules = [
          "d ${cfg.stateDir} 0700 ${cfg.user} ${cfg.group} -"
        ];

        systemd.services.matrix-pi-bot = {
          description = "Matrix ⇄ pi bridge";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "sops-install-secrets.service"
          ];
          # The token may not be deployed yet, or the homeserver may be down:
          # keep retrying instead of burning the start limit.
          startLimitIntervalSec = 0;
          environment = {
            MATRIX_HOMESERVER = cfg.homeserverUrl;
            MATRIX_USER_ID = cfg.userId;
            MATRIX_TOKEN_FILE = cfg.tokenFile;
            MATRIX_ALLOWED_USERS = lib.concatStringsSep "," cfg.allowedUsers;
            MATRIX_ALLOWED_ROOMS = lib.concatStringsSep "," cfg.allowedRooms;
            MATRIX_WORKSPACE = cfg.workspace;
            MATRIX_STATE_DIR = cfg.stateDir;
            PI_BIN = "${cfg.package}/bin/pi";
            PI_ARGS = lib.escapeShellArgs cfg.piArgs;
            PI_TIMEOUT_SECONDS = toString cfg.timeoutSeconds;
            MATRIX_STREAM = if cfg.stream then "1" else "0";
            MATRIX_STREAM_INTERVAL = toString cfg.streamIntervalSeconds;
            LOG_LEVEL = cfg.logLevel;
            # systemd.nix already defines a PATH for every unit; replace it so
            # the agent also sees the system profile (user tools, wrappers).
            PATH = lib.mkForce (
              lib.concatStringsSep ":" [
                "${config.system.path}/bin"
                "${config.system.path}/sbin"
                runtimePath
              ]
            );
            PYTHONUNBUFFERED = "1";
          };
          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = cfg.group;
            WorkingDirectory = cfg.workspace;
            ExecStart = "${bridge}/bin/matrix-pi-bot";
            Restart = "always";
            RestartSec = 15;
            KillMode = "mixed";
            # The agent writes files in the workspace and runs nix builds, so
            # it needs a normal writable home; do not sandbox it away.
            NoNewPrivileges = true;
          };
        };
      };
    };
}
